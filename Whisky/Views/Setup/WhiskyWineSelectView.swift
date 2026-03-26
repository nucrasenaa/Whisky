//
//  WhiskyWineSelectView.swift
//  Whisky
//
//  This file is part of Whisky.
//
//  Whisky is free software: you can redistribute it and/or modify it under the terms
//  of the GNU General Public License as published by the Free Software Foundation,
//  either version 3 of the License, or (at your option) any later version.
//
//  Whisky is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
//  without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
//  See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License along with Whisky.
//  If not, see https://www.gnu.org/licenses/.
//

import SwiftUI
import WhiskyKit

struct WhiskyWineEngine: Identifiable, Codable, Hashable {
    var id: String { name }
    let name: String
    let description: String
    let url: URL
}

struct WhiskyWineSelectView: View {
    @Binding var engineURL: URL
    @Binding var path: [SetupStage]

    @State private var selectedEngine: WhiskyWineEngine = Self.engines[0]

    // Default engines. In a real scenario, this could be fetched from a remote JSON.
    static let engines: [WhiskyWineEngine] = [
        WhiskyWineEngine(name: "WhiskyWine (Standard)",
                         description: "setup.engine.standard.description",
                         url: URL(string: "https://data.getwhisky.app/Wine/Libraries.tar.gz")
                                ?? URL(fileURLWithPath: "")),
        WhiskyWineEngine(name: "Wine 10 (Experimental)",
                         description: "setup.engine.wine10.description",
                         url: URL(string: "https://data.getwhisky.app/Wine/Libraries-10.tar.gz")
                                ?? URL(fileURLWithPath: "")),
        WhiskyWineEngine(name: "WS12WineCX23.7.1_3",
                         description: "Engine based on CrossOver 23.7.1",
                         url: URL(string: "https://data.getwhisky.app/Wine/WS12WineCX23.7.1_3.tar.xz")
                                ?? URL(fileURLWithPath: "")),
        WhiskyWineEngine(name: "WS12WineCX24.0.7_7",
                         description: "Engine based on CrossOver 24.0.7",
                         url: URL(string: "https://data.getwhisky.app/Wine/WS12WineCX24.0.7_7.tar.xz")
                                ?? URL(fileURLWithPath: "")),
        WhiskyWineEngine(name: "WS12WineSikarugir10.0_4",
                         description: "Sikarugir Wine 10 Engine",
                         url: URL(string: "https://data.getwhisky.app/Wine/WS12WineSikarugir10.0_4.tar.xz")
                                ?? URL(fileURLWithPath: ""))
    ]

    var body: some View {
        VStack {
            VStack {
                Text("setup.whiskywine.select")
                    .font(.title)
                    .fontWeight(.bold)
                Text("setup.whiskywine.select.subtitle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                List(Self.engines, selection: $selectedEngine) { engine in
                    VStack(alignment: .leading) {
                        Text(engine.name)
                            .fontWeight(.semibold)
                        Text(LocalizedStringKey(engine.description))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .tag(engine)
                }
                .listStyle(.bordered)
                .frame(height: 120)

                Spacer()
            }
            .padding(.horizontal)

            Spacer()

            HStack {
                Button("setup.quit") {
                    exit(0)
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("setup.next") {
                    engineURL = selectedEngine.url
                    path.append(.whiskyWineDownload)
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .frame(width: 400, height: 280)
    }
}
