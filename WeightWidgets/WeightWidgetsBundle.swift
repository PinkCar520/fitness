//
//  WeightWidgetsBundle.swift
//  WeightWidgets
//
//  Created by 草莓凤梨 on 2025/9/10.
//

import WidgetKit
import SwiftUI

@main
struct WeightWidgetsBundle: WidgetBundle {
    var body: some Widget {
        WeightWidgets()
        WeightWidgetsControl()
        InsightsWidget()
        WeeklySummaryWidget()
    }
}
