import Foundation
import Cadova

/// A complete set of baseplates and spacers partitioned to fit a 3D printer bed.
///
/// `BaseplateSet` takes a target footprint (e.g., furniture interior dimensions) and
/// automatically partitions it into printable pieces that fit within the specified
/// print bed size. It generates:
/// - Main baseplate pieces filling the grid-aligned area
/// - Supplementary pieces for partial grid units
/// - Front/back padding spacers for non-grid-aligned depth
/// - Side padding spacers for non-grid-aligned width
///
public struct BaseplateSet: Geometry3D {
    let footprint: Vector2D
    let printbedSize: Vector2D
    let frontPadding: Double
    let paddingChamferSize: Double
    let options: Set<Baseplate.Option>

    /// Creates a new baseplate set for the given footprint and print bed constraints.
    /// - Parameters:
    ///   - footprint: The target area to fill with baseplates.
    ///   - printbedSize: The maximum dimensions of individual printed parts.
    ///   - frontPadding: Space reserved at the front for non-grid padding (default: 0).
    ///   - paddingChamferSize: Bottom chamfer depth for spacer edges (default: 1mm).
    public init(
        footprint: Vector2D,
        printbedSize: Vector2D,
        frontPadding: Double = 0,
        paddingChamferSize: Double = 1,
        options: Set<Baseplate.Option> = [.tabs]
    ) {
        self.footprint = footprint
        self.printbedSize = printbedSize
        self.frontPadding = frontPadding
        self.paddingChamferSize = paddingChamferSize
        self.options = options
    }

    public var body: any Geometry3D {
        Baseplate.Foundation.Tab(height: 1).measuringBounds { _, tabBounds in
            let tabDepth = tabBounds.maximum.y
            let stackSpacing = 1.0
            let height = Baseplate.Socket().height - 0.4 + Units3D.size.z

            let bedSizeWithoutTabs = printbedSize - tabDepth
            let maxBedUnitsX = Int(floor(bedSizeWithoutTabs.x / Units2D.size.x))
            let maxBedUnitsY = Int(floor(bedSizeWithoutTabs.y / Units2D.size.y))

            let xUnits = Int(floor((footprint.x - tabDepth) / Units2D.size.x))
            let yUnits = Int(floor((footprint.y - tabDepth) / Units2D.size.y))

            let mainPartXUnits = min(xUnits, maxBedUnitsX)
            let mainPartYUnits = min(yUnits, maxBedUnitsY)

            let mainPartCountX = xUnits / mainPartXUnits
            let mainPartCountY = yUnits / mainPartYUnits


            let sparePartUnitsX = (xUnits - mainPartXUnits) % maxBedUnitsX
            let sparePartUnitsY = (yUnits - mainPartYUnits) % maxBedUnitsY
            let sidePadding = (footprint.x - (Double(xUnits) * Units2D.size.x)) / 2
            let backPadding = (footprint.y - Double(yUnits) * Units2D.size.y) - frontPadding

            Stack(.y, spacing: stackSpacing, alignment: .centerX) {
                if frontPadding > 0 {
                    paddingRow(
                        totalUnits: xUnits,
                        sidePadding: sidePadding,
                        maxPartWidth: printbedSize.x,
                        depth: frontPadding,
                        height: height,
                        chamferSize: paddingChamferSize,
                        interlockingSide: .top,
                        stackSpacing: stackSpacing,
                        singlePart: Parts.frontSpacer,
                        leftPart: Parts.frontSpacerLeft,
                        rightPart: Parts.frontSpacerRight,
                        centerBaseName: "Front spacer, center"
                    )
                }

                for yIndex in 0..<mainPartCountY {
                    Stack(.x, spacing: stackSpacing) {
                        if sidePadding > 0 {
                            Spacer(
                                size: Vector3D(sidePadding, Double(mainPartYUnits) * Units2D.size.y, height),
                                bottomChamferDepth: paddingChamferSize,
                                interlockingSide: .right,
                                interlockingAlignment: .mid,
                                interlockingOffset: 0
                            )
                            .inPart(Part("Side spacer, left \(yIndex + 1)"))
                        }

                        for xIndex in 0..<mainPartCountX {
                            Baseplate(size: Units2D(x: mainPartXUnits, y: mainPartYUnits), options: options)
                                .inPart(Part("Baseplate \(yIndex + 1)-\(xIndex + 1)"))
                        }

                        if sparePartUnitsX > 0 {
                            Baseplate(size: Units2D(x: sparePartUnitsX, y: mainPartYUnits), options: options)
                                .inPart(Part("Baseplate, narrow \(yIndex + 1)"))
                        }

                        if sidePadding > 0 {
                            Spacer(
                                size: Vector3D(sidePadding, Double(mainPartYUnits) * Units2D.size.y, height),
                                bottomChamferDepth: paddingChamferSize,
                                interlockingSide: .left,
                                interlockingAlignment: .mid,
                                interlockingOffset: 0
                            )
                            .inPart(Part("Side spacer, right \(yIndex + 1)"))
                        }
                    }
                }

                if sparePartUnitsY > 0 {
                    Stack(.x, spacing: stackSpacing) {
                        if sidePadding > 0 {
                            Spacer(
                                size: Vector3D(sidePadding, Double(sparePartUnitsY) * Units2D.size.y, height),
                                bottomChamferDepth: paddingChamferSize,
                                interlockingSide: .right,
                                interlockingAlignment: .mid,
                                interlockingOffset: 0
                            )
                            .inPart(Parts.sideSpacerLeftShort)
                        }

                        for xIndex in 0..<mainPartCountX {
                            Baseplate(size: Units2D(x: mainPartXUnits, y: sparePartUnitsY), options: options)
                                .inPart(Part("Baseplate, shallow \(xIndex + 1)"))
                        }

                        if sparePartUnitsX > 0 {
                            Baseplate(size: Units2D(x: sparePartUnitsX, y: sparePartUnitsY), options: options)
                                .inPart(Parts.baseplateCorner)
                        }

                        if sidePadding > 0 {
                            Spacer(
                                size: Vector3D(sidePadding, Double(sparePartUnitsY) * Units2D.size.y, height),
                                bottomChamferDepth: paddingChamferSize,
                                interlockingSide: .left,
                                interlockingAlignment: .mid,
                                interlockingOffset: 0
                            )
                            .inPart(Parts.sideSpacerRightShort)
                        }
                    }
                }

                if backPadding > 0 {
                    paddingRow(
                        totalUnits: xUnits,
                        sidePadding: sidePadding,
                        maxPartWidth: printbedSize.x,
                        depth: backPadding,
                        height: height,
                        chamferSize: paddingChamferSize,
                        interlockingSide: .bottom,
                        stackSpacing: stackSpacing,
                        singlePart: Parts.backSpacer,
                        leftPart: Parts.backSpacerLeft,
                        rightPart: Parts.backSpacerRight,
                        centerBaseName: "Back spacer, center"
                    )
                }
            }
        }
    }

    @GeometryBuilder3D
    private func paddingRow(
        totalUnits: Int,
        sidePadding: Double,
        maxPartWidth: Double,
        depth: Double,
        height: Double,
        chamferSize: Double,
        interlockingSide: Rectangle.Side,
        stackSpacing: Double,
        singlePart: Part,
        leftPart: Part,
        rightPart: Part,
        centerBaseName: String
    ) -> any Geometry3D {
        let unitSize = Units2D.size.x
        let totalWidth = Double(totalUnits) * unitSize + sidePadding * 2

        // Max units that fit in a side piece (which includes sidePadding)
        let maxSideUnits = Int(floor((maxPartWidth - sidePadding) / unitSize))
        // Max units that fit in a center piece (full grid units only)
        let maxCenterUnits = Int(floor(maxPartWidth / unitSize))

        if totalWidth <= maxPartWidth {
            // Single piece fits on print bed
            Spacer(
                size: Vector3D(totalWidth, depth, height),
                bottomChamferDepth: chamferSize,
                interlockingSide: interlockingSide,
                interlockingAlignment: .mid,
                interlockingOffset: 0
            )
            .inPart(singlePart)
        } else if totalUnits <= maxSideUnits * 2 {
            // Two pieces (left + right) can cover all units
            let leftUnits = totalUnits / 2
            let rightUnits = totalUnits - leftUnits

            Stack(.x, spacing: stackSpacing) {
                Spacer(
                    size: Vector3D(sidePadding + Double(leftUnits) * unitSize, depth, height),
                    bottomChamferDepth: chamferSize,
                    interlockingSide: interlockingSide,
                    interlockingAlignment: .max,
                    interlockingOffset: 0
                )
                .inPart(leftPart)

                Spacer(
                    size: Vector3D(Double(rightUnits) * unitSize + sidePadding, depth, height),
                    bottomChamferDepth: chamferSize,
                    interlockingSide: interlockingSide,
                    interlockingAlignment: .min,
                    interlockingOffset: 0
                )
                .inPart(rightPart)
            }
        } else {
            // Need center pieces: left + N center pieces + right
            // Side pieces get maxSideUnits each, center pieces get the rest
            let sideUnitsTotal = maxSideUnits * 2
            let centerUnitsTotal = totalUnits - sideUnitsTotal
            let centerPartCount = Int(ceil(Double(centerUnitsTotal) / Double(maxCenterUnits)))
            let centerUnitsBase = centerUnitsTotal / centerPartCount
            let centerUnitsRemainder = centerUnitsTotal % centerPartCount

            Stack(.x, spacing: stackSpacing) {
                // Left piece
                Spacer(
                    size: Vector3D(sidePadding + Double(maxSideUnits) * unitSize, depth, height),
                    bottomChamferDepth: chamferSize,
                    interlockingSide: interlockingSide,
                    interlockingAlignment: .max,
                    interlockingOffset: 0
                )
                .inPart(leftPart)

                // Center pieces - first 'remainder' pieces get one extra unit
                for i in 0..<centerPartCount {
                    let units = centerUnitsBase + (i < centerUnitsRemainder ? 1 : 0)
                    Spacer(
                        size: Vector3D(Double(units) * unitSize, depth, height),
                        bottomChamferDepth: chamferSize,
                        interlockingSide: interlockingSide,
                        interlockingAlignment: .mid,
                        interlockingOffset: 0
                    )
                    .inPart(Part(centerBaseName + " \(i + 1)"))
                }

                // Right piece
                Spacer(
                    size: Vector3D(Double(maxSideUnits) * unitSize + sidePadding, depth, height),
                    bottomChamferDepth: chamferSize,
                    interlockingSide: interlockingSide,
                    interlockingAlignment: .min,
                    interlockingOffset: 0
                )
                .inPart(rightPart)
            }
        }
    }
}

public extension BaseplateSet {
    /// Named parts generated by `BaseplateSet` for use with part modification.
    enum Parts {
        /// The corner baseplate piece (narrow and shallow).
        public static let baseplateCorner = Part("Baseplate, corner")
        /// The short left side spacer adjacent to shallow baseplates.
        public static let sideSpacerLeftShort = Part("Side spacer, left short")
        /// The short right side spacer adjacent to shallow baseplates.
        public static let sideSpacerRightShort = Part("Side spacer, right short")
        /// The front spacer when it fits in a single piece.
        public static let frontSpacer = Part("Front spacer")
        /// The left portion of the front spacer when split.
        public static let frontSpacerLeft = Part("Front spacer, left")
        /// The right portion of the front spacer when split.
        public static let frontSpacerRight = Part("Front spacer, right")
        /// The back spacer when it fits in a single piece.
        public static let backSpacer = Part("Back spacer")
        /// The left portion of the back spacer when split.
        public static let backSpacerLeft = Part("Back spacer, left")
        /// The right portion of the back spacer when split.
        public static let backSpacerRight = Part("Back spacer, right")
    }
}
