//
//  ChartTransformer.swift
//  Charts
//
//  Created by Daniel Cohen Gindi on 6/3/15.
//
//  Copyright 2015 Daniel Cohen Gindi & Philipp Jahoda
//  A port of MPAndroidChart for iOS
//  Licensed under Apache License 2.0
//
//  https://github.com/danielgindi/ios-charts
//

import Foundation
import CoreGraphics

/// Transformer class that contains all matrices and is responsible for transforming values into pixels on the screen and backwards.
public class ChartTransformer: NSObject
{
    /// matrix to map the values to the screen pixels
    internal var _matrixValueToPx = CGAffineTransformIdentity

    /// matrix for handling the different offsets of the chart
    internal var _matrixOffset = CGAffineTransformIdentity

    internal var _viewPortHandler: ChartViewPortHandler

    public init(viewPortHandler: ChartViewPortHandler)
    {
        _viewPortHandler = viewPortHandler
    }

    /// Prepares the matrix that transforms values to pixels. Calculates the scale factors from the charts size and offsets.
    public func prepareMatrixValuePx(chartXMin chartXMin: Double, deltaX: CGFloat, deltaY: CGFloat, chartYMin: Double)
    {
        let scaleX = (_viewPortHandler.contentWidth / deltaX)
        let scaleY = (_viewPortHandler.contentHeight / deltaY)

        // setup all matrices
        _matrixValueToPx = CGAffineTransformIdentity
        _matrixValueToPx = CGAffineTransformScale(_matrixValueToPx, scaleX, -scaleY)
        _matrixValueToPx = CGAffineTransformTranslate(_matrixValueToPx, CGFloat(-chartXMin), CGFloat(-chartYMin))
    }

    /// Prepares the matrix that contains all offsets.
    public func prepareMatrixOffset(inverted: Bool)
    {
        if (!inverted)
        {
            _matrixOffset = CGAffineTransformMakeTranslation(_viewPortHandler.offsetLeft, _viewPortHandler.chartHeight - _viewPortHandler.offsetBottom)
        }
        else
        {
            _matrixOffset = CGAffineTransformMakeScale(1.0, -1.0)
            _matrixOffset = CGAffineTransformTranslate(_matrixOffset, _viewPortHandler.offsetLeft, -_viewPortHandler.offsetTop)
        }
    }
    
    /// Transforms an Entry into a transformed point for bar chart
    public func getTransformedValueBarChart(entry entry: ChartDataEntry, xIndex: Int, dataSetIndex: Int, phaseY: CGFloat, dataSetCount: Int, groupSpace: CGFloat) -> CGPoint
    {
        // calculate the x-position, depending on datasetcount
        let x = CGFloat(xIndex + (xIndex * (dataSetCount - 1)) + dataSetIndex) + groupSpace * CGFloat(xIndex) + groupSpace / 2.0
        let y = entry.value
        
        var valuePoint = CGPoint(
            x: x,
            y: CGFloat(y) * phaseY
        )
        
        pointValueToPixel(&valuePoint)
        
        return valuePoint
    }
    
    /// Transforms an Entry into a transformed point for horizontal bar chart
    public func getTransformedValueHorizontalBarChart(entry entry: ChartDataEntry, xIndex: Int, dataSetIndex: Int, phaseY: CGFloat, dataSetCount: Int, groupSpace: CGFloat) -> CGPoint
    {
        // calculate the x-position, depending on datasetcount
        let x = CGFloat(xIndex + (xIndex * (dataSetCount - 1)) + xIndex) + groupSpace * CGFloat(xIndex) + groupSpace / 2.0
        let y = entry.value
        
        var valuePoint = CGPoint(
            x: CGFloat(y) * phaseY,
            y: x
        )
        
        pointValueToPixel(&valuePoint)
        
        return valuePoint
    }

    /// Transform an array of points with all matrices.
    // VERY IMPORTANT: Keep matrix order "value-touch-offset" when transforming.
    public func pointValuesToPixel(inout pts: [CGPoint])
    {
        let trans = valueToPixelMatrix
        for (var i = 0, count = pts.count; i < count; i++)
        {
            pts[i] = CGPointApplyAffineTransform(pts[i], trans)
        }
    }
    
    public func pointValueToPixel(inout point: CGPoint)
    {
        point = CGPointApplyAffineTransform(point, valueToPixelMatrix)
    }
    
    /// Transform a rectangle with all matrices.
    public func rectValueToPixel(inout r: CGRect)
    {
        r = CGRectApplyAffineTransform(r, valueToPixelMatrix)
    }
    
    /// Transform a rectangle with all matrices with potential animation phases.
    public func rectValueToPixel(inout r: CGRect, phaseY: CGFloat)
    {
        // multiply the height of the rect with the phase
        var bottom = r.origin.y + r.size.height
        bottom *= phaseY
        let top = r.origin.y * phaseY
        r.size.height = bottom - top
        r.origin.y = top

        r = CGRectApplyAffineTransform(r, valueToPixelMatrix)
    }
    
    /// Transform a rectangle with all matrices.
    public func rectValueToPixelHorizontal(inout r: CGRect)
    {
        r = CGRectApplyAffineTransform(r, valueToPixelMatrix)
    }
    
    /// Transform a rectangle with all matrices with potential animation phases.
    public func rectValueToPixelHorizontal(inout r: CGRect, phaseY: CGFloat)
    {
        // multiply the height of the rect with the phase
        var right = r.origin.x + r.size.width
        right *= phaseY
        let left = r.origin.x * phaseY
        r.size.width = right - left
        r.origin.x = left
        
        r = CGRectApplyAffineTransform(r, valueToPixelMatrix)
    }

    /// transforms multiple rects with all matrices
    public func rectValuesToPixel(inout rects: [CGRect])
    {
        let trans = valueToPixelMatrix
        
        for (var i = 0; i < rects.count; i++)
        {
            rects[i] = CGRectApplyAffineTransform(rects[i], trans)
        }
    }
    
    /// Transforms the given array of touch points (pixels) into values on the chart.
    public func pixelsToValue(inout pixels: [CGPoint])
    {
        let trans = pixelToValueMatrix
        
        for (var i = 0; i < pixels.count; i++)
        {
            pixels[i] = CGPointApplyAffineTransform(pixels[i], trans)
        }
    }
    
    /// Transforms the given touch point (pixels) into a value on the chart.
    public func pixelToValue(inout pixel: CGPoint)
    {
        pixel = CGPointApplyAffineTransform(pixel, pixelToValueMatrix)
    }
    
    /// - returns: the x and y values in the chart at the given touch point
    /// (encapsulated in a PointD). This method transforms pixel coordinates to
    /// coordinates / values in the chart.
    public func getValueByTouchPoint(point: CGPoint) -> CGPoint
    {
        return CGPointApplyAffineTransform(point, pixelToValueMatrix)
    }
    
    public var valueToPixelMatrix: CGAffineTransform
    {
        return
            CGAffineTransformConcat(
                CGAffineTransformConcat(
                    _matrixValueToPx,
                    _viewPortHandler.touchMatrix
                ),
                _matrixOffset
        )
    }
    
    public var pixelToValueMatrix: CGAffineTransform
    {
        return CGAffineTransformInvert(valueToPixelMatrix)
    }
}