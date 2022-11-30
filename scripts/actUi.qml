import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import Vedder.vesc.utility 1.0

import Vedder.vesc.commands 1.0
import Vedder.vesc.configparams 1.0

Item {
    id: mainItem
    anchors.fill: parent
    anchors.margins: 5

    property Commands mCommands: VescIf.commands()
    property ConfigParams mMcConf: VescIf.mcConfig()

    ColumnLayout {
        id: gaugeColumn
        anchors.fill: parent
        RowLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            CustomGauge {
                id: posGauge
                Layout.fillWidth: true
                Layout.preferredWidth: gaugeColumn.width * 0.45
                Layout.preferredHeight: width
                maximumValue: 55
                minimumValue: -55
                tickmarkScale: 1
                labelStep: 5
                value: slider1.value
                unitText: "mm"
                typeText: "Position"
            }
            CustomGauge {
                id: powerGauge
                Layout.fillWidth: true
                Layout.preferredWidth: gaugeColumn.width * 0.45
                Layout.preferredHeight: width
                maximumValue: 2000
                minimumValue: 0
                tickmarkScale: 1
                labelStep: 200
                value: 0
                unitText: "W"
                typeText: "Power"
            }
            CustomGauge {
                id: speedGauge
                Layout.fillWidth: true
                Layout.preferredWidth: gaugeColumn.width * 0.45
                Layout.preferredHeight: width
                maximumValue: 30
                minimumValue: -30
                tickmarkScale: 1
                labelStep:5
                value: 0
                precision: 1
                unitText: "mm/s"
                typeText: "Speed"
                property color posColor:  Utility.getAppHexColor("tertiary3")
                property color negColor:  Utility.getAppHexColor("tertiary1")
                nibColor: value >= 0 ? posColor: negColor
            }
        }
        RowLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Slider {
                id:slider1
                Layout.fillWidth: true
                from: -55
                to: 55
                value: 0
            }
           
            Slider {
                id:slider2
                Layout.fillWidth: true
                from: 0
                to: 100
                value: 10
            }
        }
        RowLayout{
             CheckBox {
                id: activeBox
                Layout.fillWidth: true
                text: "Active"
                checked: false
            }
             Label {
                id: statusLabel
                text: "Status:Inactive"
            }Label {
                id: speedLabel
                text: "Speed: 0%"
            }        
        }
        RowLayout {
            Button{
                Layout.fillWidth: true
                text: "Activate"
                onClicked: {
                   activeBox.checked=true
                }
            }
            Button{
                Layout.fillWidth: true
                text: "Stop"
                onClicked: {
                    slider1.value=0
      

                }
            }
            Button{
                Layout.fillWidth: true
                text: "Deactivate"
                onClicked: {
                    activeBox.checked=false
              
                }
            }
        }
    }
   Timer {
        running: true
        repeat: true
        interval: 100
        
        onTriggered: {
           speedLabel.text="Speed:" + slider2.value.toFixed(1) +"%"
  
            var buffer = new ArrayBuffer(8);
            var dv = new DataView(buffer);
            dv.setUint16(0,slider1.value*100)
            dv.setUint16(2,slider1.value*100)
            dv.setUint16(4,slider1.value*100)
            dv.setUint8(6, slider2.value)
            dv.setUint8(7, activeBox.checked?7:0)
            mCommands.sendCustomAppData(buffer)
        }
    } 
   Connections {
        target: mCommands
        
        function onCustomAppDataReceived(data) {
            var dv = new DataView(data)
            var ind = 0
            var pos = dv.getInt16(ind); ind += 2
            var power = dv.getInt16(ind); ind += 2
            var speed = dv.getInt16(ind); ind += 2
            var flags = dv.getInt8(ind)
            posGauge.value=pos
            powerGauge.value=power
            speedGauge.value=6.0*(speed/10000)
            var text=""
            if (flags&0x01)
                text="Active"
            else
                text="Inactive"
            
            statusLabel.text="Status: "+text
            
            
        }
    }
}
