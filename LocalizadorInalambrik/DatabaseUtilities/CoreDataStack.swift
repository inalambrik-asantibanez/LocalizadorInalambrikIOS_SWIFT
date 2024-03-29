//
//  CoreDataStack.swift
//  LocalizadorInalambrik
//
//  Created by Peter Arcentales on 8/21/19.
//  Copyright © 2019 Inalambrilk. All rights reserved.
//

import CoreData
import UIKit

struct CoreDataStack {
    private let model: NSManagedObjectModel
    internal let coordinator: NSPersistentStoreCoordinator
    private let modelURL: URL
    internal let dbURL: URL
    internal let persistingContext: NSManagedObjectContext
    internal let backgroundContext: NSManagedObjectContext
    let context: NSManagedObjectContext
    
    //It gets the used instance context of the CoreData
    static func shared() -> CoreDataStack
    {
        struct Singleton {
            static var shared = CoreDataStack(modelName: "LocalizadorInalambrik")!
        }
        return Singleton.shared
    }
    
    init?(modelName: String)
    {
        //It asumes that the model is installed in the main bundle
        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "momd") else {
            DeviceUtilities.shared().printData("Not Able to find \(modelName) in the main bundle")
            return nil
        }
        self.modelURL = modelURL
        
        //It tries to create the model from the URL
        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            DeviceUtilities.shared().printData("Not able to create a model from \(modelURL)")
            return nil
        }
        self.model = model
        
        //It creates the store coordinator
        coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        
        //It creates a persistingcontext (private queue) and a child one (main queue)
        //It creates a context and connect it to the coordinator
        persistingContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        persistingContext.persistentStoreCoordinator = coordinator
        
        //It creates a context and add connect it to the coordinator
        context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.parent = persistingContext
        
        //It creates a background context child of main context
        backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        backgroundContext.parent = context
        
        //It adds a sqlite store located in the documents folder
        let fm = FileManager.default
        
        guard let docUrl = fm.urls(for: .documentDirectory, in: .userDomainMask).first else
        {
            return nil
        }
        self.dbURL = docUrl.appendingPathComponent("model.sqlite")
        
        //Options for migrations
        let options = [
            NSInferMappingModelAutomaticallyOption: true,
            NSMigratePersistentStoresAutomaticallyOption:true
        ]
        
        do {
            try addStoreCoordinator(NSSQLiteStoreType, configuration: nil, storeURL: dbURL, options: options as [NSObject : AnyObject]?)
        }
        catch {
            DeviceUtilities.shared().printData("Not able to add store at \(dbURL)")
        }
    }
    
    func addStoreCoordinator(_ storeType: String, configuration: String?, storeURL: URL, options : [NSObject:AnyObject]?) throws {
        try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: dbURL, options: nil)
    }
}

internal extension CoreDataStack  {
    
    func dropAllData() throws {
        //In case of migration it deletes the DB (just truncate the tables)
        try coordinator.destroyPersistentStore(at: dbURL, ofType:NSSQLiteStoreType , options: nil)
        try addStoreCoordinator(NSSQLiteStoreType, configuration: nil, storeURL: dbURL, options: nil)
    }
}

extension CoreDataStack
{
    //It saves the context
    func saveContext() throws {
        context.performAndWait() {
            
            if self.context.hasChanges {
                do {
                    try self.context.save()
                } catch {
                    DeviceUtilities.shared().printData("Error while saving main context: \(error)")
                }
                
                // now we save in the background
                self.persistingContext.perform() {
                    do {
                        try self.persistingContext.save()
                    } catch {
                        DeviceUtilities.shared().printData("Error while saving persisting context: \(error)")
                    }
                }
            }
        }
    }
    
    //It makes an autosave
    func autoSave(_ delayInSeconds : Int) {
        
        if delayInSeconds > 0 {
            do {
                try saveContext()
                DeviceUtilities.shared().printData("Autosaving")
            } catch {
                DeviceUtilities.shared().printData("Error while autosaving")
            }
            
            let delayInNanoSeconds = UInt64(delayInSeconds) * NSEC_PER_SEC
            let time = DispatchTime.now() + Double(Int64(delayInNanoSeconds)) / Double(NSEC_PER_SEC)
            
            DispatchQueue.main.asyncAfter(deadline: time) {
                self.autoSave(delayInSeconds)
            }
        }
    }
    
    //It fetchs the User Information
    func fetchUser(_ predicate: NSPredicate, entityName: String) throws -> User?
    {
        let ft = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        ft.predicate = predicate
        guard let user = (try context.fetch(ft) as! [User]).first else
            {
            return nil
        }
        return user
    }
    
    //It fetchs the LocationReport Information
    func fetchLocationReport(_ predicate: NSPredicate? = nil, entityName: String, sorting: NSSortDescriptor? = nil) throws -> LocationReportInfo?
    {
        let ft = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        ft.predicate = predicate
        if let sorting = sorting {
            ft.sortDescriptors = [sorting]
        }
        guard let locationReportInfo = (try context.fetch(ft) as! [LocationReportInfo]).first else
        {
            return nil
        }
        return locationReportInfo
    }
    
    //It fetch the LocationReport List
    func fetchLocationReports(_ predicate: NSPredicate,_ entityName: String,  sorting: NSSortDescriptor? = nil,_ fetchLimit: Int? = nil) throws -> [LocationReportInfo]?
    {
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fr.predicate = predicate
        if fetchLimit! > 0
        {
            fr.fetchLimit = ConstantsController().NUMBER_OF_MAX_PENDING_REPORTS_TO_SEND
        }
        if let sorting = sorting {
            fr.sortDescriptors = [sorting]
        }
        guard let lrs = try context.fetch(fr) as? [LocationReportInfo]
        else
        {
            return nil
        }
        return lrs
    }
    
    //It loads the user information
    public func loadUserInformation() -> User? {
        let predicate = NSPredicate(format: "userId == 1 ")
        var user: User?
        do {
            try user = CoreDataStack.shared().fetchUser(predicate, entityName: User.name)
        } catch {
            DeviceUtilities.shared().printData("Error while fetching location: \(error)")
        }
        return user
    }
    
    //it saves the context of the App for further CoreData use
    public func save(){
        do {
            try CoreDataStack.shared().saveContext()
            DeviceUtilities.shared().printData("Se va a guardar el contexto")
        }
        catch
        {
            DeviceUtilities.shared().printData("Error: Error while saving data: \(error)")
        }
    }
    
}
