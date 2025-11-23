import { common, wantAgent } from '@kit.AbilityKit';
import { notificationManager } from '@kit.NotificationKit';
import { createWantAgent, publishNotification, openNotificationPermission } from '../common/utils/NotificationUtil';
import Logger from '../common/utils/Logger';
import CommonConstants, { DOWNLOAD_STATUS } from '../common/constants/CommonConstants';
import { backgroundTaskManager } from '@kit.BackgroundTasksKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct Index {
  private context = this.getUIContext().getHostContext() as common.UIAbilityContext;
  private requestId: number = -1;
  @State downloadStatus: number = DOWNLOAD_STATUS.INITIAL;
  @State downloadProgress: number = 0;
  private notificationTitle: string = '';
  private wantAgentObj: object = {} as wantAgent.WantAgentInfo;
  private interval: number = -1;
  private isSupport: boolean = true;

  aboutToAppear() {
    openNotificationPermission(this.context);
    const bundleName = this.context.abilityInfo.bundleName;
    const abilityName = this.context.abilityInfo.name;
    createWantAgent(bundleName, abilityName).then(agent => {
      this.wantAgentObj = agent;
    });

    notificationManager.isSupportTemplate('downloadTemplate').then(support => {
      this.isSupport = support;
    });
  }

  onBackPress() {
    this.cancel();
  }

  build() {
    Column() {
      Column() {
        Row() {
          Image($r('app.media.ic_image'))
            .objectFit(ImageFit.Fill)
            .width(24)
            .height(24)

          Text(CommonConstants.DOWNLOAD_FILE)
            .fontSize(12)
            .textAlign(TextAlign.Center)
            .fontColor(Color.Black)
            .margin({ left: 8 })
        }
        .width('100%')

        Progress({
          value: this.downloadProgress,
          total: CommonConstants.PROGRESS_TOTAL
        }).width('100%')

        Row() {
          if (this.downloadStatus === DOWNLOAD_STATUS.INITIAL) {
            this.customButton($r('app.string.button_download'), (): Promise<void> => this.start())
          } else if (this.downloadStatus === DOWNLOAD_STATUS.DOWNLOADING) {
            Row() {
              this.cancelButton()
              this.customButton($r('app.string.button_pause'), (): Promise<void> => this.pause())
            }
          } else if (this.downloadStatus === DOWNLOAD_STATUS.PAUSE) {
            Row() {
              this.cancelButton()
              this.customButton($r('app.string.button_resume'), (): Promise<void> => this.resume())
            }
          } else {
            Text('Download completed!')
              .fontSize(12)
          }
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
      }
      .width('85%')
      .height(108)
      .backgroundColor(Color.White)
      .borderRadius(16)
      .justifyContent(FlexAlign.SpaceBetween)
      .padding(16)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Grey)
    .justifyContent(FlexAlign.Center)
  }

  // Background Operations
  async start() {
    this.notificationTitle = $r('app.string.notification_title_download').toString();
    this.downloadProgress = 0;
    this.downloadStatus = DOWNLOAD_STATUS.DOWNLOADING;

    this.requestSuspend();
    this.download();
  }

  async resume() {
    this.notificationTitle = $r('app.string.notification_title_download').toString();
    this.downloadStatus = DOWNLOAD_STATUS.DOWNLOADING;
    this.requestSuspend();
    this.download();
  }

  async pause() {
    this.notificationTitle = $r('app.string.notification_title_pause').toString();
    this.downloadStatus = DOWNLOAD_STATUS.PAUSE;
    clearInterval(this.interval);
    this.cancelSuspend();
    if (this.isSupport) {
      publishNotification(this.downloadProgress, this.notificationTitle, this.wantAgentObj);
    }
  }

  async cancel() {
    this.downloadProgress = 0;
    this.downloadStatus = DOWNLOAD_STATUS.INITIAL;
    clearInterval(this.interval);
    this.cancelSuspend();
    notificationManager.cancel(CommonConstants.NOTIFICATION_ID);
  }

  requestSuspend() {
    const reason = 'File downloading';
    try {
      const info = backgroundTaskManager.requestSuspendDelay(reason, () => {
        Logger.warn('⏱ Transient task about to timeout.');
        this.cancel();
      });
      this.requestId = info.requestId;
      Logger.info(`Transient task started with ID: ${this.requestId}`);
    } catch (err) {
      Logger.error(`requestSuspendDelay failed: ${(err as BusinessError).message}`);
    }
  }

  cancelSuspend() {
    try {
      if (this.requestId !== -1) {
        backgroundTaskManager.cancelSuspendDelay(this.requestId);
        Logger.info(`Transient task canceled (ID: ${this.requestId})`);
        this.requestId = -1;
      }
    } catch (err) {
      Logger.error(`cancelSuspendDelay failed: ${(err as BusinessError).message}`);
    }
  }

  download() {
    this.interval = setInterval(async () => {
      if (this.downloadProgress >= CommonConstants.PROGRESS_TOTAL) {
        clearInterval(this.interval);
        this.notificationTitle = $r('app.string.notification_title_finish').toString();
        this.downloadStatus = DOWNLOAD_STATUS.FINISHED;
        this.cancelSuspend();
        Logger.info('Download finished.');
      } else {
        this.downloadProgress += CommonConstants.PROGRESS_SPEED;
        Logger.info(`Downloading... progress: ${this.downloadProgress}`);
      }

      if (this.isSupport) {
        publishNotification(this.downloadProgress, this.notificationTitle, this.wantAgentObj);
      }
    }, CommonConstants.UPDATE_FREQUENCY);
  }

  @Builder
  customButton(textResource: Resource, click: Function = () => {
  }) {
    Button(textResource)
      .fontSize(8)
      .backgroundColor($r('app.color.button_color'))
      .buttonsStyle()
      .onClick(() => {
        click();
      })
  }

  @Builder
  cancelButton() {
    Button($r('app.string.button_cancel'))
      .buttonsStyle()
      .backgroundColor($r('app.color.cancel_button_color'))
      .fontColor($r('app.color.button_color'))
      .margin({ right: 8 })
      .onClick(() => {
        this.cancel();
      })
  }
}

@Extend(Button)
function buttonsStyle() {
  .constraintSize({ minWidth: 64 })
  .height(24)
  .borderRadius(14)
  .fontSize(8)
}