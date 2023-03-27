//
//  ArucoMarker.swift
//  arucopublisher
//
//  Created by Yelshat Duskaliyev on 27.03.2023.
//

import Foundation

@objc public class ArucoMarker: NSObject {
    @objc var id: Int = 0
    @objc var pose: FloatTriple
    @objc var orientation: FloatTriple
    @objc var corners: Corners? = nil
    @objc var imageVectors: OrientationVectors?

    @objc init(id: Int, pose: FloatTriple, orientation: FloatTriple, corners: Corners?, imageVectors: OrientationVectors?) {
        self.id = id
        self.pose = pose
        self.orientation = orientation
        self.corners = corners
        self.imageVectors = imageVectors
        super.init()
    }
}


@objc class FloatTriple: NSObject {
    @objc var x: Float
    @objc var y: Float
    @objc var z: Float

    @objc init(x: Float, y: Float, z: Float) {
        self.x = x
        self.y = y
        self.z = z
        super.init()
    }

}

@objc class Corners: NSObject {
    @objc var topLeft: FloatTriple
    @objc var topRight: FloatTriple
    @objc var bottomRight: FloatTriple
    @objc var bottomLeft: FloatTriple
    @objc var imageWidth: Int
    @objc var imageHeight: Int

    @objc init(topLeft: FloatTriple, topRight: FloatTriple, bottomRight: FloatTriple, bottomLeft: FloatTriple, imageWidth: Int, imageHeight: Int) {
        self.topLeft = topLeft
        self.topRight = topRight
        self.bottomRight = bottomRight
        self.bottomLeft = bottomLeft
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
        super.init()
    }
}

@objc class OrientationVectors: NSObject {
    @objc var base: CGPoint
    @objc var x: CGPoint
    @objc var y: CGPoint
    @objc var z: CGPoint
    @objc var imageWidth: Int
    @objc var imageHeight: Int

    @objc init(base: CGPoint, x: CGPoint, y: CGPoint, z: CGPoint, imageWidth: Int, imageHeight: Int) {
        self.base = base
        self.x = x
        self.y = y
        self.z = z
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
        super.init()
    }
}
