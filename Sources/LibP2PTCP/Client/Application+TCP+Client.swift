//
//  Application+TCP+Client.swift
//  
//
//  Created by Brandon Toms on 3/19/22.
//

import LibP2P

extension Application.Clients.Provider {
    public static var tcp: Self {
        .init {
            $0.clients.use(key: TCPClient.key) {
                $0.tcp.client.shared.delegating(to: $0.eventLoopGroup.next())
            }
        }
    }
}

extension Application.TCP {
    public var client: Client {
        .init(application: self.application)
    }

    public struct Client {
        let application: Application

        public var shared: TCPClient {
            let lock = self.application.locks.lock(for: Key.self)
            lock.lock()
            defer { lock.unlock() }
            if let existing = self.application.storage[Key.self] {
                return existing
            }
            let new = TCPClient(
                eventLoopGroupProvider: .shared(self.application.eventLoopGroup),
                configuration: self.configuration,
                backgroundActivityLogger: self.application.logger
            )
            self.application.storage.set(Key.self, to: new) {
                try $0.syncShutdown()
            }
            return new
        }

        public var configuration: TCPClient.Configuration {
            get {
                self.application.storage[ConfigurationKey.self] ?? .init()
            }
            nonmutating set {
                if self.application.storage.contains(Key.self) {
                    self.application.logger.warning("Cannot modify client configuration after client has been used.")
                } else {
                    self.application.storage[ConfigurationKey.self] = newValue
                }
            }
        }

        struct Key: StorageKey, LockKey {
            typealias Value = TCPClient
        }

        struct ConfigurationKey: StorageKey {
            typealias Value = TCPClient.Configuration
        }
    }
}
