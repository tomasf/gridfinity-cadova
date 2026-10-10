import Cadova
import Helical
import Foundation

// A filler piece that bridges gaps between baseplates and enclosure edges.
struct Spacer: Geometry3D {
    let size: Vector3D
    let bottomChamferDepth: Double
    let interlockingSide: Rectangle.Side
    let interlockingAlignment: AxisAlignment
    let interlockingOffset: Double

    var body: any Geometry3D {
        let interlockingAxis = interlockingSide.axis.otherAxis
        let depth = size.xy[interlockingAxis]
        let unitCount = Int(floor(depth / Units2D.size[interlockingAxis]))
        let interlockingLength = Double(unitCount) * Units2D.size[interlockingAxis]
        let offset = (size.xy[interlockingAxis] - interlockingLength) * interlockingAlignment.fraction + interlockingOffset
        let tab = Baseplate.Foundation.Tab(height: Units3D.size.z)

        let clearanceHole = Baseplate.Foundation.bolt.clearanceHole(depth: depth, entry: .recessedHead)
            .rotated(x: -90°)
            .translated(x: Units2D.size.x / 2, y: -4, z: Units3D.size.z / 2)

        let negativeConnection = tab.negativePair
            .adding {
                Baseplate.Foundation.nut.nutTrap(depthClearance: depth)
                    .adding {
                        ClearanceHole(diameter: Baseplate.Foundation.bolt.thread.majorDiameter, depth: depth)
                            .translated(z: -depth)
                    }
                    .rotated(x: -90°)
                    .translated(x: Units2D.size.x / 2, y: 2, z: Units3D.size.z / 2)
            }

        Box(size)
            .cuttingEdgeProfile(.chamfer(depth: bottomChamferDepth), on: interlockingSide.otherBottomEdges)
            .replaced {
                switch (interlockingSide.axis, interlockingSide.axisDirection) {
                case (.x, .negative):
                    $0.adding {
                        tab.positivePair
                            .rotated(z: 90°)
                            .repeated(along: .y, step: Units2D.size.y, count: unitCount)
                            .translated(y: offset)
                    }.subtracting {
                        clearanceHole
                            .rotated(z: 90°)
                            .repeated(along: .y, step: Units2D.size.y, count: unitCount)
                            .translated(y: offset)
                    }

                case (.x, .positive):
                    $0.subtracting {
                        negativeConnection
                            .rotated(z: 90°)
                            .repeated(along: .y, step: Units2D.size.y, count: unitCount)
                            .translated(x: size.x, y: offset)
                    }

                case (.y, .negative):
                    $0.subtracting {
                        negativeConnection
                            .repeated(along: .x, step: Units2D.size.x, count: unitCount)
                            .translated(x: offset)
                    }

                case (.y, .positive):
                    $0.adding {
                        tab.positivePair
                            .repeated(along: .x, step: Units2D.size.x, count: unitCount)
                            .translated(x: offset, y: size.y)
                    }.subtracting {
                        clearanceHole
                            .repeated(along: .x, step: Units2D.size.x, count: unitCount)
                            .translated(x: offset, y: size.y)
                    }

                @unknown default:
                    preconditionFailure("Unsupported interlocking side")
                }
            }
    }
}

extension Rectangle.Side {
    var otherBottomEdges: Box.Edges {
        let allEdges: Box.Edges = [.bottomBack, .bottomFront, .bottomLeft, .bottomRight]
        return allEdges.subtracting([bottomBoxEdge])
    }

    var bottomBoxEdge: Box.Edge {
        switch axis {
        case .x: .alongY(xSide: axisDirection, zSide: .min)
        case .y: .alongX(ySide: axisDirection, zSide: .min)
        @unknown default: preconditionFailure("Unsupported axis")
        }
    }
}
