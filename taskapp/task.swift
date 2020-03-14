//
//  task.swift
//  taskapp
//
//  Created by Yuto Masamura on 2020/03/10.
//  Copyright © 2020 yuto.masamura. All rights reserved.
//
import RealmSwift

class Task: Object {
    // 管理用 ID。プライマーキー
    @objc dynamic var id = 0
    
    // タイトル
    @objc dynamic var title = ""
    
    // 内容
    @objc dynamic var contents = ""
    
    // カテゴリー
    @objc dynamic var category = ""
    
    // 日時
    @objc dynamic var date = Date()
    
    // id をプライマーキーとして設定
    override static func primaryKey() -> String? {
        return "id"
    }
}
