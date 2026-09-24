// System tray via StatusNotifierItem. Replaces waybar's `tray` module.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

QtObject {
    id: root

    readonly property var items: SystemTray.items.values
    readonly property bool hasItems: items.length > 0

    // Items that expose a menu (most do) vs. ones that only react to clicks.
    function itemsWithMenu() {
        var out = []
        for (var i = 0; i < items.length; i++)
            if (items[i].hasMenu)
                out.push(items[i])
        return out
    }
}
