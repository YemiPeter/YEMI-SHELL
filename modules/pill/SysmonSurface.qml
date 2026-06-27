import QtQuick
import "Singletons"

/**
 * System monitor surface for the pill. Shows CPU, memory, swap, network,
 * disk and GPU stats in a compact dial layout.
 */
PillSurface {
    id: root
    mTop: 15
    mLeft: 17
    mRight: 17
    mBottom: 14

    implicitHeight: grid.implicitHeight + 24 * s
    implicitWidth: 392 * s

    onActiveChanged: {
        if (active) Sysmon.open = true;
        else Sysmon.open = false;
    }

    Grid {
        id: grid
        anchors.centerIn: parent
        columns: 2
        spacing: 12 * root.s

        // CPU
        Item {
            width: 160 * root.s
            height: 70 * root.s
            Rectangle {
                anchors.fill: parent
                radius: 10 * root.s
                color: Theme.tileBg
                border.width: 1
                border.color: Theme.border

                Column {
                    anchors.centerIn: parent
                    spacing: 2 * root.s

                    Text {
                        text: "CPU"
                        color: Theme.subtle
                        font.family: Theme.font
                        font.pixelSize: 10 * root.s
                    }

                    Text {
                        text: Sysmon.cpu + "%"
                        color: Theme.cream
                        font.family: Theme.font
                        font.pixelSize: 20 * root.s
                        font.weight: Font.DemiBold
                        font.features: { "tnum": 1 }
                    }

                    Rectangle {
                        width: 100 * root.s
                        height: 3 * root.s
                        radius: 1.5 * root.s
                        color: Qt.alpha(Theme.cream, 0.15)

                        Rectangle {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            height: parent.height
                            width: parent.width * (Sysmon.cpu / 100)
                            radius: parent.radius
                            color: Sysmon.cpu > 80 ? Theme.verm : Theme.flameGlow
                        }
                    }
                }
            }
        }

        // Memory
        Item {
            width: 160 * root.s
            height: 70 * root.s
            Rectangle {
                anchors.fill: parent
                radius: 10 * root.s
                color: Theme.tileBg
                border.width: 1
                border.color: Theme.border

                Column {
                    anchors.centerIn: parent
                    spacing: 2 * root.s

                    Text {
                        text: "RAM"
                        color: Theme.subtle
                        font.family: Theme.font
                        font.pixelSize: 10 * root.s
                    }

                    Text {
                        text: Sysmon.memPct + "%"
                        color: Theme.cream
                        font.family: Theme.font
                        font.pixelSize: 20 * root.s
                        font.weight: Font.DemiBold
                        font.features: { "tnum": 1 }
                    }

                    Text {
                        text: Sysmon.memUsedGb.toFixed(1) + " / " + Sysmon.memTotalGb.toFixed(1) + " GB"
                        color: Theme.dim
                        font.family: Theme.font
                        font.pixelSize: 9 * root.s
                    }
                }
            }
        }

        // GPU (if present)
        Item {
            visible: Sysmon.hasGpu
            width: 160 * root.s
            height: 70 * root.s
            Rectangle {
                anchors.fill: parent
                radius: 10 * root.s
                color: Theme.tileBg
                border.width: 1
                border.color: Theme.border

                Column {
                    anchors.centerIn: parent
                    spacing: 2 * root.s

                    Text {
                        text: Sysmon.gpuVendor.toUpperCase()
                        color: Theme.subtle
                        font.family: Theme.font
                        font.pixelSize: 10 * root.s
                    }

                    Text {
                        text: Sysmon.gpu + "%"
                        color: Theme.cream
                        font.family: Theme.font
                        font.pixelSize: 20 * root.s
                        font.weight: Font.DemiBold
                        font.features: { "tnum": 1 }
                    }

                    Text {
                        text: Sysmon.gpuTemp > 0 ? Sysmon.gpuTemp + "°C" : ""
                        color: Sysmon.gpuTemp > 80 ? Theme.verm : Theme.dim
                        font.family: Theme.font
                        font.pixelSize: 9 * root.s
                    }
                }
            }
        }

        // Disk
        Item {
            width: 160 * root.s
            height: 70 * root.s
            Rectangle {
                anchors.fill: parent
                radius: 10 * root.s
                color: Theme.tileBg
                border.width: 1
                border.color: Theme.border

                Column {
                    anchors.centerIn: parent
                    spacing: 2 * root.s

                    Text {
                        text: "DISK"
                        color: Theme.subtle
                        font.family: Theme.font
                        font.pixelSize: 10 * root.s
                    }

                    Text {
                        text: Sysmon.diskPct + "%"
                        color: Theme.cream
                        font.family: Theme.font
                        font.pixelSize: 20 * root.s
                        font.weight: Font.DemiBold
                        font.features: { "tnum": 1 }
                    }

                    Text {
                        text: Sysmon.uptime
                        color: Theme.dim
                        font.family: Theme.font
                        font.pixelSize: 9 * root.s
                    }
                }
            }
        }
    }
}
