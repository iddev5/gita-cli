#include "Toast.h"
#include <wintoastlib.h>

using namespace WinToastLib;

class Handler : public IWinToastHandler {
public:
    void toastActivated() const {  }
    void toastActivated(int actionIndex) const {  }
    void toastDismissed(WinToastDismissalReason state) const {  }
    void toastFailed() const {  }

}

int toast_init() {
    if (!WinToast::isCompatible()) {
        return TOAST_INIT_ERROR;
    }

    WinToast::instance()->setAppName(L"Bhagavad Gita");
    WinToast::instance()->setAppUserModeId(L"Gita-CLI");

    if (!WinToast::instance()->initialize()) {
        return TOAST_UNREACHABLE;
    }

    return TOAST_OK;
}

void toast_deinit() {  }

int toast_show(uint16_t *text) {
    WinToastTemplate templ(WinToastTemplate::Text02);
    templ.setTextField(text, WinToastTemplate::FirstLine);

    if (WinToast::instance()->showToast(templ, new Handler()) < 0) {
        return TOAST_SHOW_ERROR;
    }

    return TOAST_OK;
}


