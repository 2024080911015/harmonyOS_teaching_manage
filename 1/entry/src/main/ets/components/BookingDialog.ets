import { RoomInfo, TimeSlot, BookingRequest, ClassroomUserRole, TimeSlotStatus } from '../models/ClassroomModels'
import { BookingStatus } from '../models/DataModels'

@CustomDialog
export struct BookingDialog {
  controller: CustomDialogController
  @Prop classroom: RoomInfo | null = null
  @Prop timeSlot: TimeSlot | null = null
  @Prop userRole: ClassroomUserRole = ClassroomUserRole.STUDENT
  onConfirm?: (applicantName: string, purpose: string) => void // 确认回调
  
  @State purpose: string = ''
  @State applicantName: string = ''
  @State contactPhone: string = ''
  @State participantCount: number = 0
  @State notes: string = ''
  
  // 提交申请
  submitBooking() {
    // 验证必填项
    if (!this.purpose || !this.applicantName || !this.contactPhone) {
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
    
    // 验证人数
    if (this.participantCount > 0 && this.classroom && this.participantCount > this.classroom.capacity) {
      AlertDialog.show({
        title: '提示',
        message: `参与人数超过教室最大容量（${this.classroom.capacity}人）`,
        confirm: {
          value: '确定',
          action: () => {}
        }
      })
      return
    }
    
    // 构建预约请求
    const booking: BookingRequest = {
      classroomId: this.classroom?.id || '',
      date: this.timeSlot?.date || '',
      startTime: this.timeSlot?.startTime || '',
      endTime: this.timeSlot?.endTime || '',
      purpose: this.purpose,
      applicant: this.applicantName,
      applicantRole: this.userRole,
      id: '',
      classroomName: '',
      timeSlot: '',
      applicantId: '',
      status: BookingStatus.PENDING_ACADEMIC,
      createTime: '',
      updateTime: ''
    }
    
    // 调用确认回调，更新时间段状态
    if (this.onConfirm) {
      this.onConfirm(this.applicantName, this.purpose)
    }
    
    // 显示成功提示
    AlertDialog.show({
      title: '申请成功',
      message: `您已成功申请借用教室 ${this.classroom?.roomNumber}\n时间：${this.timeSlot?.date} ${this.timeSlot?.startTime}-${this.timeSlot?.endTime}\n该时段已被占用`,
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
        Text('申请借用教室')
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
          // 教室信息卡片
          Column() {
            Row() {
              Text('教室信息')
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
              }
              .width('100%')
              .margin({ bottom: 8 })
              
              Row() {
                Text('借用时间：')
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
            }
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#f5f5f5')
          .borderRadius(8)
          .margin({ top: 16, bottom: 16 })
          
          // 申请表单
          Column() {
            // 借用用途
            Column() {
              Row() {
                Text('*')
                  .fontSize(14)
                  .fontColor('#ff4d4f')
                Text('借用缘由')
                  .fontSize(14)
                  .fontColor('#333333')
              }
              .width('100%')
              .margin({ bottom: 8 })
              
              TextArea({ placeholder: '请详细说明借用教室的原因和用途' })
                .width('100%')
                .height(80)
                .backgroundColor('#ffffff')
                .border({ width: 1, color: '#d9d9d9' })
                .borderRadius(4)
                .onChange((value) => {
                  this.purpose = value
                })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            .margin({ bottom: 16 })
            
            // 申请人姓名
            Column() {
              Row() {
                Text('*')
                  .fontSize(14)
                  .fontColor('#ff4d4f')
                Text('申请人姓名')
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
                  this.applicantName = value
                })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            .margin({ bottom: 16 })
            
            // 联系电话
            Column() {
              Row() {
                Text('*')
                  .fontSize(14)
                  .fontColor('#ff4d4f')
                Text('联系电话')
                  .fontSize(14)
                  .fontColor('#333333')
              }
              .width('100%')
              .margin({ bottom: 8 })
              
              TextInput({ placeholder: '请输入联系电话' })
                .width('100%')
                .height(40)
                .type(InputType.PhoneNumber)
                .backgroundColor('#ffffff')
                .border({ width: 1, color: '#d9d9d9' })
                .borderRadius(4)
                .onChange((value) => {
                  this.contactPhone = value
                })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            .margin({ bottom: 16 })
            
            // 参与人数
            Column() {
              Row() {
                Text('参与人数')
                  .fontSize(14)
                  .fontColor('#333333')
                if (this.classroom) {
                  Text(`（最多${this.classroom.capacity}人）`)
                    .fontSize(12)
                    .fontColor('#999999')
                }
              }
              .width('100%')
              .margin({ bottom: 8 })
              
              TextInput({ placeholder: '请输入参与人数' })
                .width('100%')
                .height(40)
                .type(InputType.Number)
                .backgroundColor('#ffffff')
                .border({ width: 1, color: '#d9d9d9' })
                .borderRadius(4)
                .onChange((value) => {
                  this.participantCount = parseInt(value) || 0
                })
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
              
              TextArea({ placeholder: '请输入备注信息' })
                .width('100%')
                .height(60)
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
          Button('确认借用')
            .width('100%')
            .height(44)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .backgroundColor('#1890ff')
            .onClick(() => {
              this.submitBooking()
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
