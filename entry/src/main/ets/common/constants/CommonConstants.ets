export default class CommonConstants {
  static readonly DOWNLOAD_FILE: string = 'Music.mp4';
  static readonly PROGRESS_TOTAL: number = 100;
  static readonly PROGRESS_SPEED: number = 2;
  static readonly UPDATE_FREQUENCY: number = 1000;
  static readonly NOTIFICATION_ID: number = 1000;
}

export enum DOWNLOAD_STATUS {
  INITIAL,
  DOWNLOADING,
  PAUSE,
  FINISHED
}