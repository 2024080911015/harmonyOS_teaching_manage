import { promptAction } from '@kit.ArkUI';
import { LeaveType, Attachment } from '../models/AppModels';
import { DataService } from '../services/DataService';

// 请假申请对话框组件
@Component
export struct LeaveRequestDialog {
  @Link isVisible: boolean;
  @State leaveType: LeaveType = LeaveType.SICK;
  @State reason: string = '';
  @State startTime: string = '';
  @State endTime: string = '';
  @State attachments: Attachment[] = [];
  
  studentId: string = '';
  studentName: string = '';
  className: string = '';
  onSuccess: () => void = () => {};
  
  private dataService: DataService = DataService.getInstance();
  
  build() {
    if (this.isVisible) {
      Column() {
        // 遮罩层
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0,0,0,0.4)')
          .onClick(() => {
            this.isVisible = false;
          })
        
        // 对话框内容
        Column() {
          // 标题栏
          Row() {
            Text('请假申请')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor('#1A1A1A')
            
            Blank()
            
            Image($r('app.media.ic_close'))
              .width(20)
              .height(20)
              .fillColor('#999999')
              .onClick(() => {
                this.isVisible = false;
              })
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 16, bottom: 16 })
          
          Divider().color('#F0F0F0')
          
          // 表单内容
          Scroll() {
            Column() {
              // 请假类型
              Column() {
                Text('请假类型 *')
                  .fontSize(14)
                  .fontColor('#666666')
                  .width('100%')
                  .margin({ bottom: 8 })
                
                Row() {
                  ForEach([LeaveType.SICK, LeaveType.PERSONAL], (type: LeaveType) => {
                    Row() {
                      Radio({ value: type, group: 'leaveType' })
                        .checked(this.leaveType === type)
                        .onChange((isChecked: boolean) => {
                          if (isChecked) {
                            this.leaveType = type;
                          }
                        })
                        .width(18)
                        .height(18)
                      
                      Text(type)
                        .fontSize(15)
                        .fontColor('#1A1A1A')
                        .margin({ left: 8 })
                    }
                    .margin({ right: 24 })
                  })
                }
                .width('100%')
              }
              .width('100%')
              .padding({ left: 20, right: 20, top: 16, bottom: 16 })
              .alignItems(HorizontalAlign.Start)
              
              // 请假原因
              Column() {
                Text('请假原因 *')
                  .fontSize(14)
                  .fontColor('#666666')
                  .width('100%')
                  .margin({ bottom: 8 })
                
                TextArea({ placeholder: '请输入请假原因', text: this.reason })
                  .width('100%')
                  .height(100)
                  .fontSize(15)
                  .fontColor('#1A1A1A')
                  .backgroundColor('#F5F5F5')
                  .borderRadius(8)
                  .padding(12)
                  .onChange((value: string) => {
                    this.reason = value;
                  })
              }
              .width('100%')
              .padding({ left: 20, right: 20, top: 8, bottom: 16 })
              .alignItems(HorizontalAlign.Start)
              
              // 开始时间
              Column() {
                Text('开始时间 *')
                  .fontSize(14)
                  .fontColor('#666666')
                  .width('100%')
                  .margin({ bottom: 8 })
                
                Row() {
                  Text(this.startTime || '请选择开始时间')
                    .fontSize(15)
                    .fontColor(this.startTime ? '#1A1A1A' : '#999999')
                    .layoutWeight(1)
                  
                  Image($r('app.media.ic_arrow_right'))
                    .width(16)
                    .height(16)
                    .fillColor('#CCCCCC')
                }
                .width('100%')
                .height(48)
                .padding({ left: 12, right: 12 })
                .backgroundColor('#F5F5F5')
                .borderRadius(8)
                .onClick(() => {
                  // 显示开始时间选择器
                  this.getUIContext().showDatePickerDialog({
                    start: new Date(),
                    end: new Date('2030-12-31'),
                    selected: this.startTime ? new Date(this.startTime) : new Date(),
                    showTime: true,
                    useMilitaryTime: true,
                    onDateAccept: (value: Date) => {
                      // 格式化日期时间：YYYY-MM-DD HH:mm
                      const year = value.getFullYear();
                      const month = String(value.getMonth() + 1).padStart(2, '0');
                      const day = String(value.getDate()).padStart(2, '0');
                      const hours = String(value.getHours()).padStart(2, '0');
                      const minutes = String(value.getMinutes()).padStart(2, '0');
                      this.startTime = `${year}-${month}-${day} ${hours}:${minutes}`;
                    }
                  });
                })
              }
              .width('100%')
              .padding({ left: 20, right: 20, top: 8, bottom: 16 })
              .alignItems(HorizontalAlign.Start)
              
              // 结束时间
              Column() {
                Text('结束时间 *')
                  .fontSize(14)
                  .fontColor('#666666')
                  .width('100%')
                  .margin({ bottom: 8 })
                
                Row() {
                  Text(this.endTime || '请选择结束时间')
                    .fontSize(15)
                    .fontColor(this.endTime ? '#1A1A1A' : '#999999')
                    .layoutWeight(1)
                  
                  Image($r('app.media.ic_arrow_right'))
                    .width(16)
                    .height(16)
                    .fillColor('#CCCCCC')
                }
                .width('100%')
                .height(48)
                .padding({ left: 12, right: 12 })
                .backgroundColor('#F5F5F5')
                .borderRadius(8)
                .onClick(() => {
                  // 显示结束时间选择器
                  this.getUIContext().showDatePickerDialog({
                    start: this.startTime ? new Date(this.startTime) : new Date(),
                    end: new Date('2030-12-31'),
                    selected: this.endTime ? new Date(this.endTime) : new Date(),
                    showTime: true,
                    useMilitaryTime: true,
                    onDateAccept: (value: Date) => {
                      // 格式化日期时间：YYYY-MM-DD HH:mm
                      const year = value.getFullYear();
                      const month = String(value.getMonth() + 1).padStart(2, '0');
                      const day = String(value.getDate()).padStart(2, '0');
                      const hours = String(value.getHours()).padStart(2, '0');
                      const minutes = String(value.getMinutes()).padStart(2, '0');
                      this.endTime = `${year}-${month}-${day} ${hours}:${minutes}`;
                    }
                  });
                })
              }
              .width('100%')
              .padding({ left: 20, right: 20, top: 8, bottom: 16 })
              .alignItems(HorizontalAlign.Start)
              
              // 附件上传（可选）
              Column() {
                Row() {
                  Text('附件上传')
                    .fontSize(14)
                    .fontColor('#666666')
                  
                  Text('（可选）')
                    .fontSize(14)
                    .fontColor('#999999')
                }
                .width('100%')
                .margin({ bottom: 8 })
                
                // 已上传附件列表
                if (this.attachments.length > 0) {
                  ForEach(this.attachments, (attachment: Attachment, index: number) => {
                    Row() {
                      Image($r('app.media.ic_info'))
                        .width(20)
                        .height(20)
                        .fillColor('#007AFF')
                        .margin({ right: 8 })
                      
                      Text(attachment.name)
                        .fontSize(14)
                        .fontColor('#1A1A1A')
                        .layoutWeight(1)
                      
                      Image($r('app.media.ic_close'))
                        .width(16)
                        .height(16)
                        .fillColor('#999999')
                        .onClick(() => {
                          this.attachments.splice(index, 1);
                        })
                    }
                    .width('100%')
                    .height(40)
                    .padding({ left: 12, right: 12 })
                    .backgroundColor(Color.White)
                    .borderRadius(8)
                    .margin({ bottom: 8 })
                  })
                }
                
                // 上传按钮
                Row() {
                  Image($r('app.media.ic_upload'))
                    .width(20)
                    .height(20)
                    .fillColor('#007AFF')
                    .margin({ right: 8 })
                  
                  Text('添加附件')
                    .fontSize(15)
                    .fontColor('#007AFF')
                }
                .width('100%')
                .height(48)
                .justifyContent(FlexAlign.Center)
                .backgroundColor('#F5F5F5')
                .borderRadius(8)
                .border({ width: 1, color: '#007AFF', style: BorderStyle.Dashed })
                .onClick(() => {
                  // 模拟文件上传
                  const newAttachment: Attachment = {
                    id: `ATT_${Date.now()}`,
                    name: `附件_${this.attachments.length + 1}.pdf`,
                    type: 'file',
                    url: '',
                    size: 1024,
                    uploadTime: new Date().toLocaleString()
                  };
                  this.attachments.push(newAttachment);
                  promptAction.showToast({ message: '附件已添加' });
                })
              }
              .width('100%')
              .padding({ left: 20, right: 20, top: 8, bottom: 16 })
              .alignItems(HorizontalAlign.Start)
            }
          }
          .layoutWeight(1)
          .scrollBar(BarState.Auto)
          
          Divider().color('#F0F0F0')
          
          // 底部按钮
          Row() {
            Button('取消')
              .width('45%')
              .height(44)
              .fontSize(16)
              .fontColor('#666666')
              .backgroundColor('#F5F5F5')
              .borderRadius(8)
              .onClick(() => {
                this.isVisible = false;
              })
            
            Button('提交申请')
              .width('45%')
              .height(44)
              .fontSize(16)
              .fontColor(Color.White)
              .backgroundColor('#007AFF')
              .borderRadius(8)
              .onClick(() => {
                this.submitLeaveRequest();
              })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .padding({ left: 20, right: 20, top: 16, bottom: 16 })
        }
        .width('90%')
        .backgroundColor(Color.White)
        .borderRadius(16)
        .position({ x: '5%', y: '50%' })
        .translate({ y: '-50%' })
        .shadow({ radius: 20, color: 'rgba(0,0,0,0.15)', offsetX: 0, offsetY: 10 })
      }
      .width('100%')
      .height('100%')
      .position({ x: 0, y: 0 })
      .zIndex(999)
    }
  }
  
  // 提交请假申请
  private submitLeaveRequest(): void {
    // 验证必填项
    if (!this.reason.trim()) {
      promptAction.showToast({ message: '请填写请假原因' });
      return;
    }
    
    if (!this.startTime) {
      promptAction.showToast({ message: '请选择开始时间' });
      return;
    }
    
    if (!this.endTime) {
      promptAction.showToast({ message: '请选择结束时间' });
      return;
    }
    
    // 验证时间有效性
    const start = new Date(this.startTime);
    const end = new Date(this.endTime);
    const now = new Date();
    
    if (start < now) {
      promptAction.showToast({ message: '开始时间不能早于当前时间' });
      return;
    }
    
    if (end <= start) {
      promptAction.showToast({ message: '结束时间必须晚于开始时间' });
      return;
    }
    
    // 提交申请
    const result = this.dataService.createLeaveRequest(
      this.studentId,
      this.studentName,
      this.className,
      this.leaveType,
      this.reason,
      this.startTime,
      this.endTime,
      this.attachments
    );
    
    if (result) {
      promptAction.showToast({ message: '请假申请已提交' });
      this.isVisible = false;
      this.resetForm();
      this.onSuccess();
    } else {
      promptAction.showToast({ message: '您有未完成的请假，无法申请新的请假' });
    }
  }
  
  // 重置表单
  private resetForm(): void {
    this.leaveType = LeaveType.SICK;
    this.reason = '';
    this.startTime = '';
    this.endTime = '';
    this.attachments = [];
  }
}
