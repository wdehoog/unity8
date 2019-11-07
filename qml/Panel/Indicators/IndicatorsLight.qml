/*
 * Copyright 2014 Canonical Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authors:
 *      Renato Araujo Oliveira Filho <renato@canonical.com>
 */

import QtQuick 2.4
import Powerd 0.1
import Lights 0.1
import QMenuModel 0.1 as QMenuModel
import Unity.Indicators 0.1 as Indicators
import Wizard 0.1

QtObject {
    id: root

    property color color: "darkgreen"
    property int onMillisec: 1000
    property int offMillisec: 3000

    property string batteryIconName: Status.batteryIcon
    property string displayStatus: Powerd.status

    onDisplayStatusChanged: {
        updateLightState("onDisplayStatusChanged")
    }

    onBatteryIconNameChanged: {
        updateLightState("onBatteryIconNameChanged")
    }

    function updateLightState(msg) {
        console.log("updateLightState: " + msg + ", icon: " + batteryIconName)
        // only show led when display is off
        if(displayStatus == Powerd.On) {
            console.log(" display == On")
            Lights.state = Lights.Off
            return
        }


        // priorities:
        //   unread messsages (highest), full&charging, charging, low   
        // Icons: (see device.s from indicator-power)
        //   %s-low-symbolic               ?
        //   %s-empty-symbolic             empty
        //   %s-caution-charging-symbolic  charging  [ 0..10]
        //   %s-low-charging-symbolic      charging  [10..30]
        //   %s-good-charging-symbolic     charging  [30..60]
        //   %s-full-symbolic              ?
        //   %s-full-charging-symbolic     charging  [60..100]
        //   %s-full-charged-symbolic      fully charged

        var lColor = ""
        var lOnMS = -1
        var lOffMS = -1
        if(_rootState.hasMessages) { 
            // Unread Notifications
            lColor  = "darkgreen"
            lOnMS   = 1000
            lOffMS  = 3000
        } else if(batteryIconName.indexOf("full-charged") >= 0) {
            // Battery Full
            lColor  = "green"
            lOnMS   = 1000
            lOffMS  = 0
        } else if(batteryIconName.indexOf("charging") >= 0) {
            // Battery Charging
            lColor  = "white"
            lOnMS   = 1000
            lOffMS  = 0
        } else if(batteryIconName.indexOf("low") >= 0
                  || batteryIconName.indexOf("empty") >= 0) {
            // Battery Low
            lColor  = "orange"
            lOnMS   = 500
            lOffMS  = 3000
        }

        console.log("  color=" + lColor + ", onMS=" + lOnMS + ", offMS=" + lOffMS)
        if(lOnMS > -1) {
            root.onMillisec = lOnMS
        }
        if(lOffMS > -1) {
            root.offMillisec = lOffMS
        }
        if(lColor.length > 0) {
            root.color = lColor
            Lights.state = Lights.On
        } else
            Lights.state = Lights.Off
    }

    // hasMessages is determined by checking for a specific icon in a dbus signal
    property var _actionGroup: QMenuModel.QDBusActionGroup {
        busType: 1
        busName: "com.canonical.indicator.messages"
        objectPath: "/com/canonical/indicator/messages"
    }

    property var _rootState: Indicators.ActionRootState {
        actionGroup: _actionGroup
        actionName: "messages"
        Component.onCompleted: actionGroup.start()

        property bool hasMessages: valid && (String(icons).indexOf("indicator-messages-new") != -1)
    }

    Component.onDestruction: Lights.state = Lights.Off

    property var _colorBinding: Binding {
        target: Lights
        property: "color"
        value: root.color
    }

    property var _onMillisecBinding: Binding {
        target: Lights
        property: "onMillisec"
        value: root.onMillisec
    }

    property var _offMillisecBinding: Binding {
        target: Lights
        property: "offMillisec"
        value: root.offMillisec
    }
}
