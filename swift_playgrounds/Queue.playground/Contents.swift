import Foundation

public enum VynDataRepo: Int {
    case inMemory = 0
    case userDefaults
}

public struct CodableVynQueue<T: Codable & Equatable> {
    private var items: [T] = []
    private let storageKey : String
    private let dataRepo: VynDataRepo
    
    public init(dataRepo: VynDataRepo = .inMemory, storageKey : String = "VynQueueStorageKey") {
        self.storageKey = storageKey
        self.dataRepo = dataRepo
        
        // Load data from UserDefaults if the repository type is userDefaults
        if dataRepo == .userDefaults {
            loadFromUserDefaults()
        }
    }

    private mutating func loadFromUserDefaults() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decodedItems = try? JSONDecoder().decode([T].self, from: data) {
            items = decodedItems
        }
    }

    private func saveToUserDefaults() {
        if dataRepo == .userDefaults {
            if let encodedItems = try? JSONEncoder().encode(items) {
                UserDefaults.standard.set(encodedItems, forKey: storageKey)
            }
        }
    }

    public mutating func enqueue(_ element: T) {
        items.append(element)
        saveToUserDefaults()
    }

    public mutating func dequeue() -> T? {
        if items.isEmpty {
            return nil
        } else {
            let tempElement = items.removeFirst()
            saveToUserDefaults()
            return tempElement
        }
    }

    public mutating func clearQueue() {
        items.removeAll()
        if dataRepo == .userDefaults {
            UserDefaults.standard.removeObject(forKey: storageKey)
        }
    }

    public func isElementAlreadyInQueue(_ element: T) -> Bool {
        return items.contains(element)
    }

    public func count() -> Int {
        return items.count
    }
    
    /**
     Provides a string representation of all items in the queue.
     - Returns: A string listing all the items in the queue.
     */
    public func snapshot() -> String {
        let itemDescriptions = items.map { "\($0)" }
        return itemDescriptions.joined(separator: ", ")
    }
    
}
var uploadingVynQueue = CodableVynQueue<String>(dataRepo: .userDefaults, storageKey: "VynStateMachineQueue")
uploadingVynQueue.enqueue("6491EB93-8FC5-4206-A410-7087CB1F9F3B")
uploadingVynQueue
uploadingVynQueue.enqueue("D6EECA55-FC8D-43E4-ADF7-B85E1A326DED")
print(uploadingVynQueue)
uploadingVynQueue.isElementAlreadyInQueue("6491EB93-8FC5-4206-A410-7087CB1F9F3B")
uploadingVynQueue.enqueue("6491EB93-8FC5-4206-A410-7087CB1F9F3B")
print(uploadingVynQueue.snapshot())
