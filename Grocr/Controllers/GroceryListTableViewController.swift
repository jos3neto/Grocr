
import UIKit
import Firebase

class GroceryListTableViewController: UITableViewController
{

  // MARK: Constants
  let listToUsers = "ListToUsers"
  let ref = Database.database().reference(withPath: "grocery-items")
  // this creates a new key ("online") in the database
  // in Firebase parlance, a reference is a key
  let usersRef = Database.database().reference(withPath: "online")
  
  // MARK: Variables
  var items: [GroceryItem] = []
  var user: User!
  var userCountBarButtonItem: UIBarButtonItem!
  
  
  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }
  
  // MARK: UIViewController Lifecycle
  
  override func viewDidLoad()
 {
    super.viewDidLoad()
	
//this method listens for changes in the database at all times
//and updates the tableView accordingly
//this method overwrites the contents of the newItems array
//with all the data blobs in the snaptshot.children array
	ref.queryOrdered(byChild:"completed").observe(.value, with:
		{ snapshot in
		//print(snapshot.value! as! NSDictionary)
		var newItems: [GroceryItem] = []
			
		for child in snapshot.children
		{
			if let snapshot = child as? DataSnapshot, let groceryItem = GroceryItem(snapshot: snapshot)
			{
				newItems.append(groceryItem)
			}
		}
		
		self.items = newItems
		self.tableView.reloadData()
		} )
	
    tableView.allowsMultipleSelectionDuringEditing = false
    
    userCountBarButtonItem = UIBarButtonItem(title: "1",
                                             style: .plain,
                                             target: self,
                                             action: #selector(userCountButtonDidTouch))
    userCountBarButtonItem.tintColor = UIColor.white
    navigationItem.leftBarButtonItem = userCountBarButtonItem
	
// this is how the current user is acquired
// this is an authentication observer, notifies when a user signs in
	Auth.auth().addStateDidChangeListener
	{ auth, user in
		guard let user = user else { return }
		self.user = User(authData: user)
		
		let currentUserRef = self.usersRef.child(self.user.uid)
		currentUserRef.setValue(self.user.email)
		currentUserRef.onDisconnectRemoveValue()
	}
	
	usersRef.observe(.value, with:
		{ snapshot in
			if snapshot.exists()
			{
				self.userCountBarButtonItem?.title = snapshot.childrenCount.description
			} else
			{
				self.userCountBarButtonItem?.title = "0"
			}
		} )
    //user = User(uid: "FakeId", email: "hungry@person.food")
  }
	
  
  // MARK: UITableView Delegate methods
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return items.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell", for: indexPath)
    let groceryItem = items[indexPath.row]
    
    cell.textLabel?.text = groceryItem.name
    cell.detailTextLabel?.text = groceryItem.addedByUser
    
    toggleCellCheckbox(cell, isCompleted: groceryItem.completed)
    
    return cell
  }
  
  override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return true
  }
  
  override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath)
  {
    if editingStyle == .delete
	{
		let groceryItem = items[indexPath.row]
// this is how an item is deleted from the database
// there are references for both the whole tree and each item
		groceryItem.ref?.removeValue()
    }
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard let cell = tableView.cellForRow(at: indexPath) else { return }
    var groceryItem = items[indexPath.row]
    let toggledCompletion = !groceryItem.completed
    
    toggleCellCheckbox(cell, isCompleted: toggledCompletion)
    groceryItem.completed = toggledCompletion
	
// this is how a value is updated
	groceryItem.ref?.updateChildValues(["completed": toggledCompletion])
  }
  
  func toggleCellCheckbox(_ cell: UITableViewCell, isCompleted: Bool)
{
    if !isCompleted
	{
      cell.accessoryType = .none
      cell.textLabel?.textColor = .black
      cell.detailTextLabel?.textColor = .black
    } else {
      cell.accessoryType = .checkmark
      cell.textLabel?.textColor = .gray
      cell.detailTextLabel?.textColor = .gray
    }
}
  
  // MARK: Add Item
  
  @IBAction func addButtonDidTouch(_ sender: AnyObject)
	{
    let alert = UIAlertController(title: "Grocery Item",
                                  message: "Add an Item",
                                  preferredStyle: .alert)
	
	let saveAction = UIAlertAction(title: "Save", style: .default)
	{ _ in
		
	  guard let textField = alert.textFields?.first,
			let text = textField.text else { return }
	
      let groceryItem = GroceryItem(name: text,
                                    addedByUser: self.user.email,
                                    completed: false)
		
	  self.ref.child(text.lowercased()).setValue(groceryItem.toAnyObject())

      self.items.append(groceryItem)
      self.tableView.reloadData()
    }
    
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
    
    alert.addTextField()
    
    alert.addAction(saveAction)
    alert.addAction(cancelAction)
    
    present(alert, animated: true, completion: nil)
   }
  
  @objc func userCountButtonDidTouch() {
    performSegue(withIdentifier: listToUsers, sender: nil)
  }
}
