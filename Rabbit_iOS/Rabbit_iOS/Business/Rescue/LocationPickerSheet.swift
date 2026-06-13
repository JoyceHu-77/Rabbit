//
//  LocationPickerSheet.swift
//  Rabbit_iOS — 地图选点 + 逆地理编码为「城市-区县」结构（供筛选器使用）
//

import CoreLocation
import MapKit
import SwiftUI

struct LocationPickerSheet: View {
    @Binding var locationText: String
    @Environment(\.dismiss) private var dismiss

    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 31.2304, longitude: 121.4737),
            span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
        )
    )
    @State private var pin = CLLocationCoordinate2D(latitude: 31.2304, longitude: 121.4737)
    @State private var isGeocoding = false
    @State private var hint = "拖动地图，把定位针放到目标区域；确认后将填入「城市-区县」"

    var body: some View {
        NavigationStack {
            Map(position: $position) {
                Annotation("选中位置", coordinate: pin) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.title)
                        .foregroundStyle(.red)
                }
            }
            .mapStyle(.standard(elevation: .flat))
            .onMapCameraChange(frequency: .continuous) { context in
                pin = context.region.center
            }
            .safeAreaInset(edge: .bottom) {
                Text(hint)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial)
            }
            .navigationTitle("地图选点")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("使用此位置") {
                        Task { await reverseGeocodeAndDismiss() }
                    }
                    .disabled(isGeocoding)
                }
            }
        }
    }

    private func reverseGeocodeAndDismiss() async {
        isGeocoding = true
        defer { isGeocoding = false }
        let loc = CLLocation(latitude: pin.latitude, longitude: pin.longitude)
        let geocoder = CLGeocoder()
        let marks: [CLPlacemark] = await withCheckedContinuation { cont in
            geocoder.reverseGeocodeLocation(loc) { places, _ in
                cont.resume(returning: places ?? [])
            }
        }
        if let pm = marks.first {
            let city = pm.locality ?? pm.administrativeArea ?? "未知市"
            let district = pm.subLocality ?? pm.subAdministrativeArea ?? ""
            let combined = district.isEmpty ? city : "\(city)-\(district)"
            locationText = combined
        } else {
            locationText = String(format: "地图定位 %.4f,%.4f", pin.latitude, pin.longitude)
        }
        dismiss()
    }
}
