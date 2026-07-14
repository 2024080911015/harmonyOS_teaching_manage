import { AppState, UserRole, Student, Teacher, User } from '../models/AppModels';
import { DataService } from './DataService';

@Observed
export class AppStateManager {
  private static instance: AppStateManager;

  @Track
  state: AppState = {
    currentUser: null,
    role: null,
    isLoggedIn: false
  };

  private dataService: DataService = DataService.getInstance();

  private constructor() {}

  public static getInstance(): AppStateManager {
    if (!AppStateManager.instance) {
      AppStateManager.instance = new AppStateManager();
    }
    return AppStateManager.instance;
  }

  // 登录 - 教师
  loginAsTeacher(teacherId: string): boolean {
    const teacher = this.dataService.getTeacherById(teacherId);
    if (teacher) {
      const user: User = {
        id: teacher.id,
        name: teacher.name,
        role: UserRole.TEACHER,
        department: teacher.department
      };
      this.dataService.setCurrentUser(user);
      this.state.currentUser = user;
      this.state.role = UserRole.TEACHER;
      this.state.isLoggedIn = true;
      return true;
    }
    return false;
  }

  // 登录 - 学生
  loginAsStudent(studentId: string): boolean {
    const student = this.dataService.getStudentById(studentId);
    if (student) {
      const user: User = {
        id: student.id,
        name: student.name,
        role: UserRole.STUDENT
      };
      this.dataService.setCurrentUser(user);
      this.state.currentUser = user;
      this.state.role = UserRole.STUDENT;
      this.state.isLoggedIn = true;
      return true;
    }
    return false;
  }
  
  // 登录 - 教务处
  loginAsAcademicAffairs(userId: string, name: string): boolean {
    const user: User = {
      id: userId,
      name: name,
      role: UserRole.ACADEMIC_AFFAIRS,
      department: '教务处'
    };
    this.dataService.setCurrentUser(user);
    this.state.currentUser = user;
    this.state.role = UserRole.ACADEMIC_AFFAIRS;
    this.state.isLoggedIn = true;
    return true;
  }
  
  // 登录 - 学院领导
  loginAsCollegeLeader(userId: string, name: string, college: string): boolean {
    const user: User = {
      id: userId,
      name: name,
      role: UserRole.COLLEGE_LEADER,
      college: college
    };
    this.dataService.setCurrentUser(user);
    this.state.currentUser = user;
    this.state.role = UserRole.COLLEGE_LEADER;
    this.state.isLoggedIn = true;
    return true;
  }

  // 登出
  logout(): void {
    this.state.currentUser = null;
    this.state.role = null;
    this.state.isLoggedIn = false;
  }

  // 获取当前用户
  getCurrentUser(): Student | Teacher | User | null {
    return this.state.currentUser;
  }

  // 获取当前角色
  getCurrentRole(): UserRole | null {
    return this.state.role;
  }

  // 判断是否为教师
  isTeacher(): boolean {
    return this.state.role === UserRole.TEACHER;
  }

  // 判断是否为学生
  isStudent(): boolean {
    return this.state.role === UserRole.STUDENT;
  }
  
  // 判断是否为教务处
  isAcademicAffairs(): boolean {
    return this.state.role === UserRole.ACADEMIC_AFFAIRS;
  }
  
  // 判断是否为学院领导
  isCollegeLeader(): boolean {
    return this.state.role === UserRole.COLLEGE_LEADER;
  }
  
  // 判断是否有审批权限
  hasApprovalPermission(): boolean {
    return this.isAcademicAffairs() || this.isCollegeLeader();
  }
}
