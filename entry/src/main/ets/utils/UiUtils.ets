import { ShowToastOptions, UIContext } from '@kit.ArkUI'
import { UserRole } from '../api/core/ApiTypes'

export function showToast(uiContext: UIContext, messageOptions: ShowToastOptions): void {
  try {
    uiContext.getPromptAction().showToast(messageOptions)
  } catch (_error) {
  }
}

export function roleLabel(role: UserRole): string {
  switch (role) {
    case UserRole.STUDENT:
      return '学生'
    case UserRole.TEACHER:
      return '教师'
    case UserRole.ACADEMIC_STAFF:
      return '教务人员'
    case UserRole.ADMIN:
      return '系统管理员'
    default:
      return '用户'
  }
}

export function statusLabel(status: string): string {
  switch (status) {
    case 'PENDING':
      return '待审批'
    case 'APPROVED':
      return '已通过'
    case 'REJECTED':
      return '已驳回'
    case 'CANCELLED':
      return '已取消'
    case 'FINISHED':
      return '已结束'
    case 'OPEN':
      return '选课中'
    case 'CLOSED':
      return '已关闭'
    case 'SELECTED':
      return '已选'
    case 'DROPPED':
      return '已退课'
    case 'PUBLISHED':
      return '已发布'
    case 'WITHDRAWN':
      return '已撤回'
    case 'AVAILABLE':
      return '可用'
    case 'MAINTENANCE':
      return '维护中'
    case 'DISABLED':
      return '已停用'
    case 'ACTIVE':
      return '正常'
    default:
      return status
  }
}

export function statusColor(status: string): string {
  switch (status) {
    case 'APPROVED':
    case 'OPEN':
    case 'SELECTED':
    case 'PUBLISHED':
    case 'AVAILABLE':
    case 'ACTIVE':
      return '#16805A'
    case 'PENDING':
      return '#A15C00'
    case 'REJECTED':
    case 'DISABLED':
      return '#C04444'
    default:
      return '#667085'
  }
}

export function statusBackground(status: string): string {
  switch (status) {
    case 'APPROVED':
    case 'OPEN':
    case 'SELECTED':
    case 'PUBLISHED':
    case 'AVAILABLE':
    case 'ACTIVE':
      return '#EAF8F2'
    case 'PENDING':
      return '#FFF4DE'
    case 'REJECTED':
    case 'DISABLED':
      return '#FDECEC'
    default:
      return '#EFF2F6'
  }
}

export function weekDayLabel(day: number): string {
  const labels: Array<string> = [
    '周日', '周一', '周二', '周三', '周四', '周五', '周六'
  ]
  if (day < 0 || day >= labels.length) {
    return '未知'
  }
  return labels[day]
}

export function weekTypeLabel(type: string): string {
  if (type === 'ODD') {
    return '单周'
  }
  if (type === 'EVEN') {
    return '双周'
  }
  return '每周'
}

export function leaveTypeLabel(type: string): string {
  if (type === 'SICK') {
    return '病假'
  }
  if (type === 'PERSONAL') {
    return '事假'
  }
  return '其他'
}

export function errorMessage(error: Object): string {
  const value: Error = error as Error
  if (value.message !== undefined && value.message.length > 0) {
    return value.message
  }
  return '操作失败，请稍后重试'
}

export function todayString(): string {
  const now: Date = new Date()
  const year: number = now.getFullYear()
  const month: string = `${now.getMonth() + 1}`.padStart(2, '0')
  const day: string = `${now.getDate()}`.padStart(2, '0')
  return `${year}-${month}-${day}`
}

export function futureDateTime(days: number): string {
  const date: Date = new Date()
  date.setDate(date.getDate() + days)
  const year: number = date.getFullYear()
  const month: string = `${date.getMonth() + 1}`.padStart(2, '0')
  const day: string = `${date.getDate()}`.padStart(2, '0')
  return `${year}-${month}-${day} 23:59:59`
}
