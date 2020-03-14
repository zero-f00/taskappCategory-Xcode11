//
//  ViewController.swift
//  taskapp
//
//  Created by Yuto Masamura on 2020/03/08.
//  Copyright © 2020 yuto.masamura. All rights reserved.
//

import UIKit
import RealmSwift
import UserNotifications

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var categorySearchBar: UISearchBar!
    
    // Realmインスタンスを取得する
    let realm = try! Realm() // ←追加
    
    // DB内のタスクが格納されるリスト。
    // 以降内容をアップデートするリスト内は自動的に更新される
    // データの一覧を取得するにはRealmクラスのobjects(_:)メソッドでクラスを指定して一覧を取得する
    // sorted(byKeyPath:ascending:)メソッドでソート（並べ替え）して配列を取り出す　日付の近い順でソート；昇順
    var taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: true) // ←追加
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // Outletで接続したtableViewにTableViewとしての機能を与えるためにデリゲートの指定
        tableView.delegate = self
        tableView.dataSource = self
        categorySearchBar.delegate = self
        
        
        // 背景をタップしたらdismissKeyboardメソッドを呼ぶように設定する
        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        self.view.addGestureRecognizer(tapGesture)
    }
    
    @objc func dismissKeyboard() {
        // キーボードを閉じる
        view.endEditing(true)
    }
    
    // segueで画面遷移する時に呼ばれるprepareメソッド
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let inputViewController:InputViewController = segue.destination as! InputViewController
        
        if segue.identifier == "cellSegue" {
            let indexPath = self.tableView.indexPathForSelectedRow
            inputViewController.task = taskArray[indexPath!.row]
        } else {
            let task = Task()
            
            let allTasks = realm.objects(Task.self)
            if allTasks.count != 0 {
                task.id = allTasks.max(ofProperty: "id")! + 1
            }
            
            inputViewController.task = task
        }
    }
    
    // 入力画面から戻ってきた時にTableViewを更新させる
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    // データの数（=セルの数）を返すメソッド
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // データの配列であるtaskArrayの要素数を返すようにする
        return taskArray.count
    }
    
    // 各セルの内容を返すメソッド
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // 再利用可能な cell を得る
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        // Cellに値を設定する
        let task = taskArray[indexPath.row]
        cell.textLabel?.text = task.title
        // フォントサイズを変更するコード
        cell.textLabel?.font = UIFont.systemFont(ofSize: 20)
        
        // 詳細テキストには日時を表示させるためカテゴリは非表示とする
        // cell.detailTextLabel?.text = task.category
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        let dateString:String = formatter.string(from: task.date)
        cell.detailTextLabel?.text = dateString
        cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 15)
        
        return cell
    }
    
    // UISearchBarが押された時に呼ばれるデリゲートメソッド
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print("検索ボタンが押されました")
        
        // 検索後にキーボードを閉じる。
        categorySearchBar.endEditing(true)
        
        // realmのインスタンスを作成
        let realm = try! Realm()
        
        // ategorySearchBarで検索されたものが空じゃない場合
        if(categorySearchBar.text! != "") {
            
            // taskArrayにRealmから絞り込んだ結果(category)だけを代入
            let predicate = NSPredicate(format: "category = %@" , categorySearchBar.text!)
            taskArray = realm.objects(Task.self).filter(predicate)
            
            // TableViewを更新させる
            tableView.reloadData()
            
            print("実行されました1")
        } else {
            // それ以外のとき
            taskArray = realm.objects(Task.self)
            print("実行されました2")
                   // TableViewを更新させる
                   tableView.reloadData()
        }
    }
    
    // 各セルを選択した時に実行されるメソッド
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "cellSegue", sender: nil) // ←追加する
    }
    
    // セルが削除可能なことを伝えるメソッド
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    // Delete ボタンが押されたに呼ばれるメソッド
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            // 削除するタスクを取得する
            let task = self.taskArray[indexPath.row]
            
            // ローカル通知をキャンセルする
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: [String(task.id)])
            
            // データベースから削除する
            try! realm.write {
                self.realm.delete(task)
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            
            // 未通知のローカル通知一覧をログ出力
            center.getPendingNotificationRequests { (requests: [UNNotificationRequest]) in
                for request in requests {
                    print("/---------------")
                    print(request)
                    print("/---------------")
                }
            }
        }
    }
}
