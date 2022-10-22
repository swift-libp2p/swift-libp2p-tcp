//
//  Application+TCP.swift
//  
//
//  Created by Brandon Toms on 3/19/22.
//

import LibP2P

extension Application {
    public var tcp: TCP_Embedded {
        .init(application: self)
    }

    public struct TCP_Embedded {
        public let application: Application
    }
}

extension Application.Transports.Provider {
    public static var tcp: Self {
        .init { app in
            app.transports.use(key: TCP_Embedded.key) {
                TCP_Embedded(application: $0, protocols:[], proxy: false, uuid:UUID())
            }
        }
    }
}
