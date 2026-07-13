import {
  AbilityConstant,
  ConfigurationConstant,
  UIAbility,
  Want
} from '@kit.AbilityKit'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { window } from '@kit.ArkUI'

import { Api } from '../api/Api'

const DOMAIN: number = 0x0000
const TAG: string = 'EntryAbility'

export default class EntryAbility extends UIAbility {
  onCreate(
    want: Want,
    launchParam: AbilityConstant.LaunchParam
  ): void {
    try {
      this.context
        .getApplicationContext()
        .setColorMode(
          ConfigurationConstant
            .ColorMode
            .COLOR_MODE_NOT_SET
        )
    } catch (err) {
      hilog.error(
        DOMAIN,
        TAG,
        'Failed to set colorMode. Cause: %{public}s',
        JSON.stringify(err)
      )
    }

    hilog.info(
      DOMAIN,
      TAG,
      '%{public}s',
      'Ability onCreate'
    )
  }

  onDestroy(): void {
    hilog.info(
      DOMAIN,
      TAG,
      '%{public}s',
      'Ability onDestroy'
    )
  }

  onWindowStageCreate(
    windowStage: window.WindowStage
  ): void {
    hilog.info(
      DOMAIN,
      TAG,
      '%{public}s',
      'Ability onWindowStageCreate'
    )

    /*
     * 初始化API，然后加载首页。
     *
     * 不要在这里再单独调用loadContent，
     * 页面加载统一放到initializeApiAndLoadPage中。
     */
    this.initializeApiAndLoadPage(windowStage)
  }

  /**
   * 初始化整个API模块并加载首页。
   *
   * Api.init()内部会初始化SessionStore，
   * 之后AuthApi、CourseApi等模块才能正常读取Token。
   */
  private async initializeApiAndLoadPage(
    windowStage: window.WindowStage
  ): Promise<void> {
    try {
      /*
       * 初始化Preferences会话存储。
       *
       * 整个应用启动时只执行一次。
       */
      await Api.init(this.context)

      hilog.info(
        DOMAIN,
        TAG,
        '%{public}s',
        'API initialized successfully'
      )

      /*
       * 设置Token失效回调。
       *
       * 目前页面还没有处理登录跳转，
       * 所以暂时只记录日志。
       */
      Api.setUnauthorizedHandler((): void => {
        hilog.info(
          DOMAIN,
          TAG,
          '%{public}s',
          'Login session expired'
        )
      })

      /*
       * API初始化成功后再加载首页。
       */
      windowStage.loadContent(
        'pages/Index',
        (err) => {
          if (err.code) {
            hilog.error(
              DOMAIN,
              TAG,
              'Failed to load content. Cause: %{public}s',
              JSON.stringify(err)
            )
            return
          }

          hilog.info(
            DOMAIN,
            TAG,
            '%{public}s',
            'Succeeded in loading the content'
          )
        }
      )
    } catch (err) {
      /*
       * SessionStore初始化失败时，
       * 记录具体错误，避免继续加载后调用API时报错。
       */
      hilog.error(
        DOMAIN,
        TAG,
        'Failed to initialize API. Cause: %{public}s',
        JSON.stringify(err)
      )
    }
  }

  onWindowStageDestroy(): void {
    hilog.info(
      DOMAIN,
      TAG,
      '%{public}s',
      'Ability onWindowStageDestroy'
    )
  }

  onForeground(): void {
    hilog.info(
      DOMAIN,
      TAG,
      '%{public}s',
      'Ability onForeground'
    )
  }

  onBackground(): void {
    hilog.info(
      DOMAIN,
      TAG,
      '%{public}s',
      'Ability onBackground'
    )
  }
}