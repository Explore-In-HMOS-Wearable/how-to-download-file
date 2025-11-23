import { common, wantAgent } from '@kit.AbilityKit';
import { notificationManager } from '@kit.NotificationKit';
import CommonConstants from '../constants/CommonConstants';
import Logger from '../utils/Logger';

/**
 * Obtains the WantAgent of an application.
 *
 * @returns WantAgent of an application.
 */
export function createWantAgent(bundleName: string, abilityName: string): Promise<object> {
  let wantAgentInfo = {
    wants: [
      {
        bundleName: bundleName,
        abilityName: abilityName
      }
    ],
    operationType: wantAgent.OperationType.START_ABILITY,
    requestCode: 0,
    wantAgentFlags: [wantAgent.WantAgentFlags.CONSTANT_FLAG]
  } as wantAgent.WantAgentInfo;
  return wantAgent.getWantAgent(wantAgentInfo);
}

/**
 * Publish notification.
 *
 * @param progress Download progress
 * @param title Notification title.
 * @param wantAgentObj The want of application.
 */
export function publishNotification(progress: number, title: string, wantAgentObj: object) {
  let template: notificationManager.NotificationTemplate = {
    name: 'downloadTemplate',
    data: {
      title: `${title}`,
      fileName: `${title}：${CommonConstants.DOWNLOAD_FILE}`,
      progressValue: progress,
      progressMaxValue: CommonConstants.PROGRESS_TOTAL,
      isProgressIndeterminate: false
    }
  };
  let notificationRequest: notificationManager.NotificationRequest = {
    id: CommonConstants.NOTIFICATION_ID,
    notificationSlotType: notificationManager.SlotType.CONTENT_INFORMATION,
    // Construct a progress bar template. The name field must be set to downloadTemplate.
    template: template,
    content: {
      notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
      normal: {
        title: `${title}：${CommonConstants.DOWNLOAD_FILE}`,
        text: ' ',
        additionalText: `${progress}%`
      }
    },
    wantAgent: wantAgentObj
  };
  notificationManager.publish(notificationRequest).catch((err: Error) => {
    Logger.error(`[ANS] publish failed,message is ${err}`);
  });
}

// Open notification permission
export function openNotificationPermission(context: common.UIAbilityContext) {
  notificationManager.requestEnableNotification(context).then(() => {
    Logger.info('Enable notification success');
  }).catch((err: Error) => {
    Logger.error('Enable notification failed because ' + JSON.stringify(err));
  });
}