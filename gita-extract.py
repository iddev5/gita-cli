#!/usr/bin/python3
import re

NUM_BOOKS = 18

with open("gita.json", "w+") as w:
    w.write("[\n")
    for fi in range(1, NUM_BOOKS + 1):
        name = f"sources/Bhagavad-Gita_(Besant_4th)_Discourse_{fi}.txt"
        with open(name) as f:
            w.write("    [\n")

            content = f.read()
            starting_pos = content.index("DISCOURSE.")

            # Remove anything prior to "DISCOURSE."
            lines = content[starting_pos + len("DISCOURSE.") + 1:]
            # Split everytime a [num] is encountered
            verses = re.split('\([0-9]+\)?', lines)

            # The last element is not a verse, it is the footer
            for i, verse in enumerate(verses[0:-1]): 
                # Split every || sanskrit num ||
                parts = re.split("॥\s*[१२३४५६७८९०]+\s*॥", verse)
                sanskrit = [s.strip() for s in parts[0].split('\n') if s]

                # Remove [ num ] from English and fix all quotes
                english = re.sub('\[[0-9]+\]', '', parts[1])
                english = re.sub('\"', '\\"', english)
                english = [s.strip() for s in english.split('\n') if s]

                # Write Json
                w.write("        {\n")
                w.write("            \"loc\": \"{}.{}\",\n".format(fi, i + 1))
                w.write("            \"sanskrit\": \"{}\",\n".format('\\n'.join(sanskrit)))
                w.write("            \"english\": \"{}\"\n".format('\\n'.join(english)))
                w.write("        }}{}\n".format(',' if i != len(verses) - 2 else ''))

            w.write("    ]{}\n".format(',' if fi != NUM_BOOKS else ''))
    w.write("]\n")
