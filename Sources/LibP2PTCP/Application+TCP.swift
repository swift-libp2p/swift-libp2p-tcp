//
//  Application+TCP.swift
//  
//
//  Created by Brandon Toms on 3/19/22.
//

import LibP2P

extension Application {
    public var tcp: TCP {
        .init(application: self)
    }

    public struct TCP {
        public let application: Application
    }
}

extension Application.Transports.Provider {
    public static var tcp: Self {
        .init { app in
            app.transports.use(key: TCP.key) {
                TCP(application: $0, protocols:[], proxy: false, uuid:UUID())
            }
        }
    }
}
