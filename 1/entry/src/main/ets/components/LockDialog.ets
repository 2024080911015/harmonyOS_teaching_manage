import { RoomInfo, TimeSlot, LockRequest } from '../models/ClassroomModels'

@CustomDialog
export struct LockDialog {
  controller: CustomDialogController
  @Prop classroom: RoomInfo | null = null
  @Prop timeSlot: TimeSlot | null = null
  
  @State examName: string = ''
  @State lockerName: string = ''
  @State department: string = ''
  @State examDate: string = ''
  @State examDuration: string = '2小时'
  @State notes: string = ''
  
  aboutToAppear() {
    // 设置默认日期为时间段日期
    if (this.timeSlot) {
      this.examDate = this.timeSlot.date
    }
  }
  
  // 提交锁定
  submitLock() {
    // 验证必填项
    if (!this.examName || !this.lockerName || !this.department) {
      AlertDialog.show({
        title: '提示',
        message: '请填写完整信息',
        confirm: {
          value: '确定',
          action: () => {}
        }
      })
      return
    }
    
    // 构建锁定请求
    const lockRequest: LockRequest = {
      classroomId: this.classroom?.id || '',
      date: this.timeSlot?.date || '',
      startTime: this.timeSlot?.startTime || '',
      endTime: this.timeSlot?.endTime || '',
      examName: this.examName,
      locker: this.lockerName
    }
    
    // 这里应该调用API提交锁定请求
    // 模拟提交成功
    AlertDialog.show({
      title: '锁定成功',
      message: `您已成功锁定教室 ${this.classroom?.roomNumber} 作为考场\n考试：${this.examName}\n时间：${this.timeSlot?.date} ${this.timeSlot?.startTime}-${this.timeSlot?.endTime}`,
      confirm: {
        value: '确定',
        action: () => {
          this.controller.close()
        }
      }
    })
  }
  
  build() {
    Column() {
      // 标题栏
      Row() {
        Text('锁定考场')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
        
        Blank()
        
        Button('关闭')
          .fontSize(14)
          .backgroundColor('#f5f5f5')
          .fontColor('#666666')
          .onClick(() => {
            this.controller.close()
          })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 15, bottom: 15 })
      .backgroundColor('#ffffff')
      
      Divider().color('#e8e8e8')
      
      Scroll() {
        Column() {
          // 警告提示
          Row() {
            Text('⚠️')
              .fontSize(16)
            Text('考务人员专用功能：锁定后该时段将无法被他人预约')
              .fontSize(13)
              .fontColor('#faad14')
          }
          .width('100%')
          .padding(12)
          .backgroundColor('#fff7e6')
          .borderRadius(8)
          .margin({ top: 16, bottom: 16 })
          
          // 教室信息卡片
          Column() {
            Row() {
              Text('考场信息')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#333333')
            }
            .width('100%')
            .margin({ bottom: 12 })
            
            if (this.classroom && this.timeSlot) {
              Row() {
                Text('教室编号：')
                  .fontSize(14)
                  .fontColor('#666666')
                Text(this.classroom.roomNumber)
                  .fontSize(14)
                  .fontColor('#333333')
                  .fontWeight(FontWeight.Medium)
              }
              .width('100%')
              .margin({ bottom: 8 })
              
              Row() {
                Text('锁定时间：')
                  .fontSize(14)
                  .fontColor('#666666')
                Text(`${this.timeSlot.date} ${this.timeSlot.startTime}-${this.timeSlot.endTime}`)
                  .fontSize(14)
                  .fontColor('#333333')
              }
              .width('100%')
              .margin({ bottom: 8 })
              
              Row() {
                Text('教室容量：')
                  .fontSize(14)
                  .fontColor('#666666')
                Text(`${this.classroom.capacity}人`)
                  .fontSize(14)
                  .fontColor('#333333')
              }
              .width('100%')
              .margin({ bottom: 8 })
              
              Row() {
                Text('教室类型：')
                  .fontSize(14)
                  .fontColor('#666666')
                Text(this.classroom.type)
                  .fontSize(14)
                  .fontColor('#333333')
              }
              .width('100%')
            }
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#f5f5f5')
          .borderRadius(8)
          .margin({ bottom: 16 })
          
          // 锁定表单
          Column() {
            // 考试名称
            Column() {
              Row() {
                Text('*')
                  .fontSize(14)
                  .fontColor('#ff4d4f')
                Text('考试名称')
                  .fontSize(14)
                  .fontColor('#333333')
              }
              .width('100%')
              .margin({ bottom: 8 })
              
              TextInput({ placeholder: '例如：2024年期末考试' })
                .width('100%')
                .height(40)
                .backgroundColor('#ffffff')
                .border({ width: 1, color: '#d9d9d9' })
                .borderRadius(4)
                .onChange((value) => {
                  this.examName = value
                })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            .margin({ bottom: 16 })
            
            // 锁定人姓名
            Column() {
              Row() {
                Text('*')
                  .fontSize(14)
                  .fontColor('#ff4d4f')
                Text('锁定人姓名')
                  .fontSize(14)
                  .fontColor('#333333')
              }
              .width('100%')
              .margin({ bottom: 8 })
              
              TextInput({ placeholder: '请输入姓名' })
                .width('100%')
                .height(40)
                .backgroundColor('#ffffff')
                .border({ width: 1, color: '#d9d9d9' })
                .borderRadius(4)
                .onChange((value) => {
                  this.lockerName = value
                })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            .margin({ bottom: 16 })
            
            // 所属部门
            Column() {
              Row() {
                Text('*')
                  .fontSize(14)
                  .fontColor('#ff4d4f')
                Text('所属部门')
                  .fontSize(14)
                  .fontColor('#333333')
              }
              .width('100%')
              .margin({ bottom: 8 })
              
              TextInput({ placeholder: '例如：教务处' })
                .width('100%')
                .height(40)
                .backgroundColor('#ffffff')
                .border({ width: 1, color: '#d9d9d9' })
                .borderRadius(4)
                .onChange((value) => {
                  this.department = value
                })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            .margin({ bottom: 16 })
            
            // 考试时长
            Column() {
              Row() {
                Text('考试时长')
                  .fontSize(14)
                  .fontColor('#333333')
              }
              .width('100%')
              .margin({ bottom: 8 })
              
              Row() {
                ForEach(['1小时', '2小时', '3小时', '4小时'], (duration: string) => {
                  Button(duration)
                    .fontSize(13)
                    .height(32)
                    .backgroundColor(this.examDuration === duration ? '#1890ff' : '#f5f5f5')
                    .fontColor(this.examDuration === duration ? '#ffffff' : '#666666')
                    .onClick(() => {
                      this.examDuration = duration
                    })
                })
              }
              .width('100%')
              .justifyContent(FlexAlign.SpaceBetween)
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            .margin({ bottom: 16 })
            
            // 备注
            Column() {
              Row() {
                Text('备注')
                  .fontSize(14)
                  .fontColor('#333333')
              }
              .width('100%')
              .margin({ bottom: 8 })
              
              TextArea({ placeholder: '请输入备注信息（如考试科目、考生人数等）' })
                .width('100%')
                .height(80)
                .backgroundColor('#ffffff')
                .border({ width: 1, color: '#d9d9d9' })
                .borderRadius(4)
                .onChange((value) => {
                  this.notes = value
                })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            .margin({ bottom: 24 })
          }
          .width('100%')
          .padding({ left: 20, right: 20 })
          
          // 提交按钮
          Button('确认锁定')
            .width('100%')
            .height(44)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .backgroundColor('#faad14')
            .onClick(() => {
              this.submitLock()
            })
        }
        .width('100%')
      }
      .layoutWeight(1)
      .padding({ left: 20, right: 20 })
    }
    .width('85%')
    .height('85%')
    .backgroundColor('#ffffff')
    .borderRadius(12)
    .shadow({ radius: 20, color: '#0000001a', offsetX: 0, offsetY: -2 })
  }
}
