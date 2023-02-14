#!/usr/bin/python3
import re

NUM_BOOKS = 18

with open("gita.json", "w+") as w:
    w.write("{\n")
    for fi in range(1, NUM_BOOKS + 1):
        name = f"sources/Bhagavad-Gita_(Besant_4th)_Discourse_{fi}.txt"
        with open(name) as f:
            w.write(f"    \"{fi}\": {{\n")

            content = f.read()
            starting_pos = content.index("DISCOURSE.")

            # Remove anything prior to "DISCOURSE."
            lines = content[starting_pos + len("DISCOURSE.") + 1:]
            # Split everytime a [num] is encountered
            verses = re.split('\([0-9]+\)', lines)

            # The last element is not a verse, it is the footer
            for i, verse in enumerate(verses[0:-1]): 
                # There are exactly 6 spaces between the Sanskrit and English text
                # for every verse.
                parts = verse.split('\n' * 6)

                # Remove || num || from Sanskrit
                sanskrit = re.sub("॥\s[१२३४५६७८९०]+\s॥", '', parts[0])
                sanskrit = [s.strip() for s in sanskrit.split('\n') if s]

                # Remove [ num ] from English and fix all quotes
                english = re.sub('\[[0-9]+\]', '', parts[1])
                english = re.sub('\"', '\\"', english)
                english = [s.strip() for s in english.split('\n') if s]

                # Write Json
                w.write(f"        \"{i+1}\": {{\n")
                w.write("            \"sanskrit\": \"{}\",\n".format('\\n'.join(sanskrit)))
                w.write("            \"english\": \"{}\"\n".format('\\n'.join(english)))
                w.write("        }}{}\n".format(',' if i != len(verses) - 2 else ''))

            w.write("    }}{}\n".format(',' if fi != NUM_BOOKS else ''))
    w.write("}\n")
