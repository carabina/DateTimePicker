//
//  DateTimePicker.swift
//  DateTimePicker
//
//  Created by Huong Do on 9/16/16.
//  Copyright © 2016 ichigo. All rights reserved.
//

import UIKit

let screenWidth = UIScreen.main.bounds.size.width
let screenHeight = UIScreen.main.bounds.size.height
let contentHeight: CGFloat = 310

@objc public class DateTimePicker: UIView {
    
    // public vars
    public var backgroundViewColor = UIColor.clear {
        didSet {
            backgroundColor = backgroundViewColor
        }
    }
    
    public var highlightColor = UIColor(red: 0/255.0, green: 199.0/255.0, blue: 194.0/255.0, alpha: 1) {
        didSet {
            todayButton.setTitleColor(highlightColor, for: .normal)
            colonLabel.textColor = highlightColor
        }
    }
    
    public var darkColor = UIColor(red: 0, green: 22.0/255.0, blue: 39.0/255.0, alpha: 1)
    
    public var daysBackgroundColor = UIColor(red: 239.0/255.0, green: 243.0/255.0, blue: 244.0/255.0, alpha: 1)
    
    public var selectedDate = Date() {
        didSet {
            resetDateTitle()
        }
    }
    
    public var dateFormat = "HH:mm dd/MM/YYYY" {
        didSet {
            resetDateTitle()
        }
    }
    
    public var minimumDate = Date(timeIntervalSinceNow: -3600 * 24 * 365 * 20) {
        didSet {
            fillDates(fromDate: minimumDate, toDate: maximumDate)
        }
    }
    public var maximumDate = Date(timeIntervalSinceNow: 3600 * 24 * 365 * 20) {
        didSet {
            fillDates(fromDate: minimumDate, toDate: maximumDate)
        }
    }
    
    public var todayButtonTitle = "Today"
    public var doneButtonTitle = "DONE"
    public var completionHandler: ((Date)->Void)?
    
    // private vars
    internal var hourTableView: UITableView!
    internal var minuteTableView: UITableView!
    internal var dayCollectionView: UICollectionView!
    
    private var contentView: UIView!
    private var dateTitleLabel: UILabel!
    private var todayButton: UIButton!
    private var colonLabel: UILabel!
    
    internal var calendar = Calendar.current
    internal var dates: [Date]! = []
    internal var components: DateComponents! {
        didSet {
            if let hour = components.hour {
                hourTableView.selectRow(at: IndexPath(row: hour, section: 0), animated: true, scrollPosition: .middle)
            }
            
            if let minute = components.minute {
                minuteTableView.selectRow(at: IndexPath(row: minute, section: 0), animated: true, scrollPosition: .middle)
            }
        }
    }
    
    
    @objc open class func show() -> DateTimePicker {
        let dateTimePicker = DateTimePicker(frame: CGRect(x: 0,
                                                          y: 0,
                                                          width: screenWidth,
                                                          height: screenHeight))
        dateTimePicker.configureView()
        UIApplication.shared.keyWindow?.addSubview(dateTimePicker)
        
        return dateTimePicker
    }
    
    private func configureView() {
        // content view
        contentView = UIView(frame: CGRect(x: 0,
                                           y: frame.height,
                                           width: frame.width,
                                           height: contentHeight))
        contentView.layer.shadowColor = UIColor(white: 0, alpha: 0.3).cgColor
        contentView.layer.shadowOffset = CGSize(width: 0, height: -2.0);
        contentView.layer.shadowRadius = 1.5
        contentView.layer.shadowOpacity = 0.5
        contentView.backgroundColor = .white
        addSubview(contentView)
        
        // title view
        let titleView = UIView(frame: CGRect(origin: CGPoint.zero,
                                             size: CGSize(width: contentView.frame.width, height: 44)))
        titleView.backgroundColor = .white
        contentView.addSubview(titleView)
        
        dateTitleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 44))
        dateTitleLabel.font = UIFont.systemFont(ofSize: 15)
        dateTitleLabel.textColor = darkColor
        dateTitleLabel.textAlignment = .center
        resetDateTitle()
        titleView.addSubview(dateTitleLabel)
        
        todayButton = UIButton(type: .system)
        todayButton.frame = CGRect(x: contentView.frame.width - 60, y: 0, width: 60, height: 44)
        todayButton.setTitle(todayButtonTitle, for: .normal)
        todayButton.setTitleColor(highlightColor, for: .normal)
        todayButton.addTarget(self, action: #selector(DateTimePicker.setToday), for: .touchUpInside)
        todayButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        titleView.addSubview(todayButton)
        
        // day collection view
        let layout = StepCollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        layout.itemSize = CGSize(width: 75, height: 80)
        
        dayCollectionView = UICollectionView(frame: CGRect(x: 0, y: 44, width: contentView.frame.width, height: 100), collectionViewLayout: layout)
        dayCollectionView.backgroundColor = daysBackgroundColor
        dayCollectionView.showsHorizontalScrollIndicator = false
        dayCollectionView.register(DateCollectionViewCell.self, forCellWithReuseIdentifier: "dateCell")
        dayCollectionView.dataSource = self
        dayCollectionView.delegate = self
        contentView.addSubview(dayCollectionView)
        
        // top & bottom borders on day collection view
        let borderTopView = UIView(frame: CGRect(x: 0, y: titleView.frame.height, width: titleView.frame.width, height: 1))
        borderTopView.backgroundColor = darkColor.withAlphaComponent(0.2)
        contentView.addSubview(borderTopView)
        
        let borderBottomView = UIView(frame: CGRect(x: 0, y: dayCollectionView.frame.origin.y + dayCollectionView.frame.height, width: titleView.frame.width, height: 1))
        borderBottomView.backgroundColor = darkColor.withAlphaComponent(0.2)
        contentView.addSubview(borderBottomView)
        
        // done button
        let doneButton = UIButton(type: .system)
        doneButton.frame = CGRect(x: 10, y: contentView.frame.height - 10 - 44, width: contentView.frame.width - 20, height: 44)
        doneButton.setTitle(doneButtonTitle, for: .normal)
        doneButton.setTitleColor(.white, for: .normal)
        doneButton.backgroundColor = darkColor.withAlphaComponent(0.5)
        doneButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 13)
        doneButton.layer.cornerRadius = 3
        doneButton.layer.masksToBounds = true
        doneButton.addTarget(self, action: #selector(DateTimePicker.dismissView), for: .touchUpInside)
        contentView.addSubview(doneButton)
        
        // hour table view
        hourTableView = UITableView(frame: CGRect(x: contentView.frame.width / 2 - 55,
                                                  y: borderBottomView.frame.origin.y + 2,
                                                  width: 55,
                                                  height: doneButton.frame.origin.y - borderBottomView.frame.origin.y - 10))
        hourTableView.rowHeight = 36
        hourTableView.contentInset = UIEdgeInsetsMake(hourTableView.frame.height / 2, 0, hourTableView.frame.height / 2, 0)
        hourTableView.showsVerticalScrollIndicator = false
        hourTableView.separatorStyle = .none
        hourTableView.delegate = self
        hourTableView.dataSource = self
        contentView.addSubview(hourTableView)
        
        // minute table view
        minuteTableView = UITableView(frame: CGRect(x: contentView.frame.width / 2,
                                                    y: borderBottomView.frame.origin.y + 2,
                                                    width: 55,
                                                    height: doneButton.frame.origin.y - borderBottomView.frame.origin.y - 10))
        minuteTableView.rowHeight = 36
        minuteTableView.contentInset = UIEdgeInsetsMake(minuteTableView.frame.height / 2, 0, minuteTableView.frame.height / 2, 0)
        minuteTableView.showsVerticalScrollIndicator = false
        minuteTableView.separatorStyle = .none
        minuteTableView.delegate = self
        minuteTableView.dataSource = self
        contentView.addSubview(minuteTableView)
        
        // colon
        colonLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 10, height: 36))
        colonLabel.center = CGPoint(x: contentView.frame.width / 2,
                                    y: (doneButton.frame.origin.y - borderBottomView.frame.origin.y - 10) / 2 + borderBottomView.frame.origin.y)
        colonLabel.text = ":"
        colonLabel.font = UIFont.boldSystemFont(ofSize: 18)
        colonLabel.textColor = highlightColor
        colonLabel.textAlignment = .center
        contentView.addSubview(colonLabel)
        
        // time separators
        let separatorTopView = UIView(frame: CGRect(x: 0, y: 0, width: 90, height: 1))
        separatorTopView.backgroundColor = darkColor.withAlphaComponent(0.2)
        separatorTopView.center = CGPoint(x: contentView.frame.width / 2, y: borderBottomView.frame.origin.y + 36)
        contentView.addSubview(separatorTopView)
        
        let separatorBottomView = UIView(frame: CGRect(x: 0, y: 0, width: 90, height: 1))
        separatorBottomView.backgroundColor = darkColor.withAlphaComponent(0.2)
        separatorBottomView.center = CGPoint(x: contentView.frame.width / 2, y: separatorTopView.frame.origin.y + 36)
        contentView.addSubview(separatorBottomView)
        
        // fill date
        fillDates(fromDate: minimumDate, toDate: maximumDate)
        updateCollectionView(to: selectedDate)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/YYYY"
        for i in 0..<dates.count {
            let date = dates[i]
            if formatter.string(from: date) == formatter.string(from: selectedDate) {
                dayCollectionView.selectItem(at: IndexPath(row: i, section: 0), animated: true, scrollPosition: .centeredHorizontally)
                break
            }
        }
        components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: selectedDate)
        
        // animate to show contentView
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: .curveEaseIn, animations: {
            self.contentView.frame = CGRect(x: 0,
                                            y: self.frame.height - contentHeight,
                                            width: self.frame.width,
                                            height: contentHeight)
        }, completion: nil)
    }
    
    func setToday() {
        selectedDate = Date()
        components = calendar.dateComponents([.day, .month, .year, .hour, .minute], from: selectedDate)
        updateCollectionView(to: selectedDate)
    }
    
    private func resetDateTitle() {
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        dateTitleLabel.text = formatter.string(from: selectedDate)
        dateTitleLabel.sizeToFit()
        dateTitleLabel.center = CGPoint(x: contentView.frame.width / 2, y: 22)
    }
    
    func fillDates(fromDate: Date, toDate: Date) {
        
        if fromDate.compare(toDate) != .orderedAscending {
            return
        }
        
        var dates: [Date] = []
        var days = DateComponents()
        
        var dayCount = 0
        repeat {
            dayCount += 1
            days.day = dayCount
            
            guard let date = calendar.date(byAdding: days, to: fromDate) else {
                break;
            }
            if date.compare(toDate) == .orderedDescending {
                break
            }
            dates.append(date)
        } while (true)
        
        self.dates = dates
        dayCollectionView.reloadData()
        
        if let index = self.dates.index(of: selectedDate) {
            dayCollectionView.selectItem(at: IndexPath(row: index, section: 0), animated: true, scrollPosition: .centeredHorizontally)
        }
    }
    
    func updateCollectionView(to currentDate: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/YYYY"
        for i in 0..<dates.count {
            let date = dates[i]
            if formatter.string(from: date) == formatter.string(from: currentDate) {
                dayCollectionView.selectItem(at: IndexPath(row: i, section: 0), animated: true, scrollPosition: .centeredHorizontally)
                break
            }
        }
    }
    
    func dismissView() {
        UIView.animate(withDuration: 0.3, animations: {
            // animate to show contentView
            self.contentView.frame = CGRect(x: 0,
                                            y: self.frame.height,
                                            width: self.frame.width,
                                            height: contentHeight)
        }) { (completed) in
            self.completionHandler?(self.selectedDate)
            self.removeFromSuperview()
        }
    }
}

extension DateTimePicker: UITableViewDataSource, UITableViewDelegate {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == hourTableView {
            return 24
        }
        return 60
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "timeCell") ?? UITableViewCell(style: .default, reuseIdentifier: "timeCell")
        
        cell.selectedBackgroundView = UIView()
        cell.textLabel?.textAlignment = tableView == hourTableView ? .right : .left
        cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        cell.textLabel?.textColor = darkColor.withAlphaComponent(0.4)
        cell.textLabel?.highlightedTextColor = highlightColor
        cell.textLabel?.text = String(format: "%02i", indexPath.row)
        
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.selectRow(at: indexPath, animated: true, scrollPosition: .middle)
        if tableView == hourTableView {
            components.hour = indexPath.row
        } else if tableView == minuteTableView {
            components.minute = indexPath.row
        }
        
        if let selected = calendar.date(from: components) {
            selectedDate = selected
        }
    }
}

extension DateTimePicker: UICollectionViewDataSource, UICollectionViewDelegate {
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dates.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "dateCell", for: indexPath) as! DateCollectionViewCell
        
        let date = dates[indexPath.item]
        cell.populateItem(date: date, highlightColor: highlightColor, darkColor: darkColor)
        
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        let date = dates[indexPath.item]
        let dayComponent = calendar.dateComponents([.day, .month, .year], from: date)
        components.day = dayComponent.day
        components.month = dayComponent.month
        components.year = dayComponent.year
        if let selected = calendar.date(from: components) {
            selectedDate = selected
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        alignScrollView(scrollView)
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            alignScrollView(scrollView)
        }
    }
    
    func alignScrollView(_ scrollView: UIScrollView) {
        if let collectionView = scrollView as? UICollectionView {
            let centerPoint = CGPoint(x: collectionView.center.x + collectionView.contentOffset.x, y: 50);
            if let indexPath = collectionView.indexPathForItem(at: centerPoint) {
                collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
                let date = dates[indexPath.item]
                let dayComponent = calendar.dateComponents([.day, .month, .year], from: date)
                components.day = dayComponent.day
                components.month = dayComponent.month
                components.year = dayComponent.year
                if let selected = calendar.date(from: components) {
                    selectedDate = selected
                }
            }
        } else if let tableView = scrollView as? UITableView {
            let relativeOffset = CGPoint(x: 0, y: tableView.contentOffset.y + tableView.contentInset.top)
            var row = round(relativeOffset.y / tableView.rowHeight)
            if tableView == hourTableView {
                row = max(min(row, 23), 0)
            } else if tableView == minuteTableView {
                row = max(min(row, 59), 0)
            }
            tableView.selectRow(at: IndexPath(row: Int(row), section: 0), animated: true, scrollPosition: .middle)
            
            if tableView == hourTableView {
                components.hour = Int(row)
            } else if tableView == minuteTableView {
                components.minute = Int(row)
            }
            
            if let selected = calendar.date(from: components) {
                selectedDate = selected
            }
        }
    }
}
