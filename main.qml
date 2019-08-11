import QtQuick 2.13
import QtQuick.Window 2.13
import QtGraphicalEffects 1.13

Window {
    id: root
    visible: true
    width: 640
    height: 480
    title: qsTr("Multitouch")
    color: "black"
    MultiPointTouchArea {
        anchors.fill: parent
        touchPoints: [
            // we want to identify three touch points
            // if the number of touch points should vary dynamically, use
            // onTouchUpdated and a repeater or dynamic component
            TouchPoint { id: point1 },
            TouchPoint { id: point2 },
            TouchPoint { id: point3 }
        ]
    }
    Item {
        id: centerPoint
        // only show visualization, if three touch events exist
        // fade can be used to animate opacity and other animations
        property bool fade: point1.pressed
                         && point2.pressed
                         && point3.pressed
        opacity: centerPoint.fade
        Behavior on opacity {
            NumberAnimation {
                easing.type: Easing.OutExpo
                duration: 2000 // 2 sec
            }
        }
        // Center of all three touchpoints
        x: (point1.x+point2.x+point3.x)/3
        y: (point1.y+point2.y+point3.y)/3
        Rectangle {
            id: centerCircle
            color: "transparent"
            //border.color: "red"

            // radius animation ranges from 100 to 200
            radius: 100+100*centerPoint.fade
            Behavior on radius {
                NumberAnimation {
                    easing.type: Easing.OutElastic
                    duration: 2000
                }
            }
            width: radius*2
            height: width
            // offset, because rectangle draws from top left
            x: -radius
            y: -radius
        }
        Rectangle {
            // This item calculates the starting angle/rotation for the months
            id: offsetArc
            color: "transparent" // "blue"
            width: 1
            height: centerCircle.radius
            transformOrigin: Item.Top
            // tan(alpha) = d_y/d_x; calc angle from coordinates and convert radians to degrees
            rotation: Math.atan2(centerPoint.y-point1.y, centerPoint.x-point1.x)/Math.PI*180
            Repeater {
                id: monthRepeater
                model: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sept", "Okt", "Nov", "Dez"]
                Item {
                    z: 100
                    // for every month repeat this item
                    // index runs from 0..11; modelData contains name of month

                    // item should rotate around its top, which is positioned at centerPoint
                    transformOrigin: Item.Top
                    rotation: (index/monthRepeater.count)*360
                    Rectangle {
                        x: 0
                        y: centerCircle.radius
                        width: 1
                        height: 50
                        color: "green"
                        Text {
                            color: "grey"
                            rotation: 90
                            text: modelData
                        }
                    }
                }
            }
            Item {
                // this item will be the source of the round
                // diagram. It is painted as a rectangular barchart
                // and a shader will bend it around the circle
                id: diagram
                // use one pixel per bar
                property int days: 365
                width: days
                height: 128
                Repeater {
                    id: diagramRepeater
                    // repeat one bar for every day
                    model: diagram.days
                    Rectangle {
                        id: diagramBar

                        //// random value generation ////
                        property real animAplitude
                        SequentialAnimation on animAplitude {
                            loops: Animation.Infinite
                            NumberAnimation {
                                from: 0
                                to: 1
                                duration: 2000
                                easing.type: Easing.InOutQuad
                            }
                            NumberAnimation {
                                from: 1
                                to: 0
                                duration: 2000
                                easing.type: Easing.InOutQuad
                            }
                        }
                        property real animPhase
                        NumberAnimation on animPhase {
                            loops: Animation.Infinite
                            from: -Math.PI
                            to: Math.PI
                            duration: 2000
                            easing.type: Easing.Linear
                        }
                        property real arg: (index/diagramRepeater.count)*10*Math.PI
                        property real wave1: Math.sin(arg)
                        property real wave2: Math.sin(arg*2+animPhase)
                        property real value: 0.5+(wave1+wave2*animAplitude)*0.25
                        //// end of random value generation ////

                        height: diagram.height*value-2
                        width: diagram.width/diagramRepeater.count
                        x: width * index
                        y: 1
                        // value is the height of the bar. Moreover the bars
                        // color should change according to its value.
                        // A layer uses a linear gradient to lookup a color
                        // implemented using a shader
                        layer.enabled: true
                        layer.effect: ShaderEffect {
                            property real value: diagramBar.value
                            property var src: ShaderEffectSource {
                                sourceItem: LinearGradient {
                                    id: gradient
                                    width: 1
                                    height: 100
                                    start: Qt.point(0, 0)
                                    end: Qt.point(0, 100)
                                    gradient: Gradient {
                                        GradientStop { position: 1.00; color: "#fcc5e4" }
                                        GradientStop { position: 0.88; color: "#fda34b" }
                                        GradientStop { position: 0.75; color: "#ff7882" }
                                        GradientStop { position: 0.50; color: "#c8699e" }
                                        GradientStop { position: 0.35; color: "#7046aa" }
                                        GradientStop { position: 0.15; color: "#0c1db8" }
                                        GradientStop { position: 0.00; color: "#020f75" }
                                    }
                                }
                                hideSource: true
                            }
                            fragmentShader: "
                                uniform lowp float value;
                                uniform sampler2D src;
                                uniform lowp float qt_Opacity;
                                void main() {
                                    lowp vec4 tex = texture2D(src, vec2(0.5, value));
                                    gl_FragColor = tex * qt_Opacity;
                                }"
                        }
                    }
                }
            }
            ShaderEffect {
                // bending effect
                x: -centerCircle.radius
                y: -centerCircle.radius
                width: centerCircle.width;
                height: centerCircle.height
                layer.enabled: true
                layer.smooth: true
                layer.mipmap: false
                layer.textureSize: Qt.size(centerCircle.width/2, centerCircle.height/2)
                property var src: ShaderEffectSource {
                    sourceItem: diagram
                    hideSource: true
                }
                vertexShader: "
                    uniform highp mat4 qt_Matrix;
                    attribute highp vec4 qt_Vertex;
                    attribute highp vec2 qt_MultiTexCoord0;
                    varying highp vec2 coord;
                    void main() {
                        coord = qt_MultiTexCoord0;
                        gl_Position = qt_Matrix * qt_Vertex;
                    }"
                fragmentShader: "
                    #define PI 3.14159265358979323844
                    varying highp vec2 coord;
                    uniform sampler2D src;
                    uniform lowp float qt_Opacity;
                    void main() {
                        highp float inner=0.3;
                        highp float outer=0.5;
                        highp vec2 c=coord-vec2(0.5);
                        highp float radius=length(c);
                        highp float angle=atan(c.y, c.x);

                        highp vec2 pol;
                        pol.s = ( radius - inner) / (outer - inner);
                        pol.t = angle * 0.5 / PI + 0.5;
                        lowp vec4 tex = texture2D(src, pol.ts);
                        gl_FragColor = tex * qt_Opacity;
                    }"
            }
        }
    }
//    Repeater {
//        model: mpta.touchCount
//        Rectangle {
//            property TouchPoint tp: mpta.touchPoints[index]
//            border.color: "red"
//            border.width: 1
//            width: 50
//            height: width
//            radius: width*0.5
//            x: tp.x-radius
//            y: tp.y-radius
//        }
//    }
}
