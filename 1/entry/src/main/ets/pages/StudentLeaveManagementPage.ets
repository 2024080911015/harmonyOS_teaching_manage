import { promptAction } from '@kit.ArkUI';
import { LeaveRequest, LeaveType, LeaveStatus, Attachment, Student } from '../models/AppModels';
import { DataService } from '../services/DataService';
import { AppStateManager } from '../services/AppStateManager';
import { User, UserRole } from '../models/DataModels';
import { EmptyState, StatusTag } from '../components/CommonComponents';

@Entry
@Component
struct StudentLeaveManagementPage {
  @State leaveRequests: LeaveRequest[] = [];
  @State currentUser: Student | null = null;
  @State showMedicalRecordDialog: boolean = false;
  @State showExtendDialog: boolean = false;
  @State selectedLeaveId: string = '';
  @State newEndTime: string = '';
  
  private dataService: DataService = DataService.getInstance();
  private appState: AppStateManager = AppStateManager.getInstance();
  
  aboutToAppear(): void {
    const user = this.appState.getCurrentUser();
    if (user) {
      this.currentUser = user as Student;
    }
    this.loadLeaveRequests();
  }
  
  build() {
    Column() {
      // 顶部标题栏
      Row() {
        Image($r('app.media.ic_arrow_right'))
          .width(24)
          .height(24)
          .fillColor('#1A1A1A')
          .onClick(() => {
            // 返回上一页
          })
        
        Text('我的请假')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1A1A1A')
          .margin({ left: 12 })
          .layoutWeight(1)
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor(Color.White)
      
      Divider().color('#F0F0F0')
      
      // 请假列表
      if (this.leaveRequests.length === 0) {
        EmptyState({ 
          text: '暂无请假记录'
        })
      } else {
        Scroll() {
          Column() {
            ForEach(this.leaveRequests, (leave: LeaveRequest) => {
              this.LeaveCard(leave)
            })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16, bottom: 16 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Auto)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
  
  // 请假卡片组件
  @Builder
  LeaveCard(leave: LeaveRequest) {
    Column() {
      // 顶部：请假类型和状态
      Row() {
        Text(leave.leaveType)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1A1A1A')
        
        Blank()
        
        StatusTag({ 
          text: leave.status,
          type: this.getStatusType(leave.status)
        })
      }
      .width('100%')
      .margin({ bottom: 12 })
      
      // 请假原因
      Row() {
        Text('请假原因：')
          .fontSize(14)
          .fontColor('#666666')
        
        Text(leave.reason)
          .fontSize(14)
          .fontColor('#1A1A1A')
          .layoutWeight(1)
      }
      .width('100%')
      .margin({ bottom: 8 })
      
      // 请假时间
      Row() {
        Text('请假时间：')
          .fontSize(14)
          .fontColor('#666666')
        
        Text(`${leave.startTime} 至 ${leave.endTime}`)
          .fontSize(14)
          .fontColor('#1A1A1A')
          .layoutWeight(1)
      }
      .width('100%')
      .margin({ bottom: 8 })
      
      // 驳回原因（如果被驳回）
      if (leave.status === LeaveStatus.REJECTED && leave.rejectReason) {
        Row() {
          Text('驳回原因：')
            .fontSize(14)
            .fontColor('#FF3B30')
          
          Text(leave.rejectReason)
            .fontSize(14)
            .fontColor('#FF3B30')
            .layoutWeight(1)
        }
        .width('100%')
        .margin({ bottom: 8 })
      }
      
      // 病历附件（如果已上传）
      if (leave.medicalRecord) {
        Row() {
          Text('病历附件：')
            .fontSize(14)
            .fontColor('#666666')
          
          Text(leave.medicalRecord.name)
            .fontSize(14)
            .fontColor('#007AFF')
            .layoutWeight(1)
        }
        .width('100%')
        .margin({ bottom: 8 })
      }
      
      // 附件列表
      if (leave.attachments.length > 0) {
        Row() {
          Text('附件：')
            .fontSize(14)
            .fontColor('#666666')
          
          Column() {
            ForEach(leave.attachments, (attachment: Attachment) => {
              Text(attachment.name)
                .fontSize(14)
                .fontColor('#007AFF')
                .margin({ bottom: 4 })
            })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .margin({ bottom: 8 })
        .alignItems(VerticalAlign.Top)
      }
      
      Divider().color('#F0F0F0').margin({ top: 8, bottom: 12 })
      
      // 操作按钮
      Row() {
        // 撤回按钮（待审批状态）
        if (leave.status === LeaveStatus.PENDING) {
          Button('撤回')
            .height(32)
            .fontSize(14)
            .fontColor('#FF3B30')
            .backgroundColor('#FFE5E5')
            .borderRadius(4)
            .onClick(() => {
              this.withdrawLeave(leave.id);
            })
        }
        
        // 上传病历按钮（病假且已通过且未上传病历）
        if (leave.leaveType === LeaveType.SICK && 
            leave.status === LeaveStatus.APPROVED && 
            !leave.medicalRecord) {
          Button('上传病历')
            .height(32)
            .fontSize(14)
            .fontColor('#007AFF')
            .backgroundColor('#E5F3FF')
            .borderRadius(4)
            .onClick(() => {
              this.selectedLeaveId = leave.id;
              this.showMedicalRecordDialog = true;
            })
        }
        
        // 申请延长按钮（病假且已上传病历且未延长）
        if (leave.leaveType === LeaveType.SICK && 
            leave.status === LeaveStatus.APPROVED && 
            leave.medicalRecord && 
            !leave.isExtended) {
          Button('申请延长')
            .height(32)
            .fontSize(14)
            .fontColor('#007AFF')
            .backgroundColor('#E5F3FF')
            .borderRadius(4)
            .onClick(() => {
              this.selectedLeaveId = leave.id;
              this.showExtendDialog = true;
            })
        }
        
        // 销假按钮
        if (this.canCancelLeave(leave)) {
          Button('销假')
            .height(32)
            .fontSize(14)
            .fontColor('#34C759')
            .backgroundColor('#E8F8ED')
            .borderRadius(4)
            .onClick(() => {
              this.cancelLeave(leave.id);
            })
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.End)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .margin({ bottom: 12 })
  }
  
  // 获取状态类型
  private getStatusType(status: LeaveStatus): 'default' | 'success' | 'warning' | 'danger' {
    switch (status) {
      case LeaveStatus.PENDING:
        return 'warning';
      case LeaveStatus.APPROVED:
      case LeaveStatus.EXTENDED:
        return 'success';
      case LeaveStatus.REJECTED:
        return 'danger';
      case LeaveStatus.WITHDRAWN:
      case LeaveStatus.CANCELLED:
        return 'default';
      default:
        return 'default';
    }
  }
  
  // 判断是否可以销假
  private canCancelLeave(leave: LeaveRequest): boolean {
    // 状态必须为已通过或已延长
    if (leave.status !== LeaveStatus.APPROVED && 
        leave.status !== LeaveStatus.EXTENDED) {
      return false;
    }
    
    // 病假：需要已上传病历
    if (leave.leaveType === LeaveType.SICK) {
      return !!leave.medicalRecord;
    }
    
    // 事假：需要假期已结束
    if (leave.leaveType === LeaveType.PERSONAL) {
      const now = new Date();
      const endTime = new Date(leave.endTime);
      return now >= endTime;
    }
    
    return false;
  }
  
  // 加载请假列表
  private loadLeaveRequests(): void {
    if (this.currentUser) {
      this.leaveRequests = this.dataService.getStudentLeaveRequests(this.currentUser.id);
    }
  }
  
  // 撤回请假
  private withdrawLeave(leaveId: string): void {
    promptAction.showDialog({
      title: '确认撤回',
      message: '确定要撤回这条请假申请吗？',
      buttons: [
        { text: '取消', color: '#666666' },
        { text: '确定', color: '#FF3B30' }
      ]
    }).then((result) => {
      if (result.index === 1) {
        const success = this.dataService.withdrawLeaveRequest(leaveId);
        if (success) {
          promptAction.showToast({ message: '请假已撤回' });
          this.loadLeaveRequests();
        } else {
          promptAction.showToast({ message: '撤回失败' });
        }
      }
    });
  }
  
  // 销假
  private cancelLeave(leaveId: string): void {
    promptAction.showDialog({
      title: '确认销假',
      message: '确定要销假吗？',
      buttons: [
        { text: '取消', color: '#666666' },
        { text: '确定', color: '#34C759' }
      ]
    }).then((result) => {
      if (result.index === 1) {
        const success = this.dataService.cancelLeaveRequest(leaveId);
        if (success) {
          promptAction.showToast({ message: '销假成功' });
          this.loadLeaveRequests();
        } else {
          promptAction.showToast({ message: '销假失败，请检查是否满足销假条件' });
        }
      }
    });
  }
}
