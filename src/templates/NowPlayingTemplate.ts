import { ImageSourcePropType } from 'react-native';
import { Template, TemplateConfig } from './Template';

export type NowPlayingButton = {
  id: string;
} & (
  | {
      type: 'shuffle' | 'add-to-library' | 'more' | 'playback' | 'repeat';
    }
  | {
      type: 'image';
      image?: ImageSourcePropType;
      /**
       * SF Symbol name (e.g. 'heart.fill'), drawn natively at the largest size CarPlay allows. Wins over
       * `image`. Not called `systemImage`: parseConfig resolves every key ending in "Image" as a bundled asset.
       */
      systemImageName?: string;
      /** Draws the button in its selected state, e.g. shuffle on. Only image buttons can show one. */
      selected?: boolean;
    }
);

export interface NowPlayingTemplateConfig extends TemplateConfig {
  albumArtistButtonEnabled?: boolean;
  upNextButtonTitle?: string;
  upNextButtonEnabled?: boolean;
  onAlbumArtistButtonPressed?(): void;
  onUpNextButtonPressed?(): void;
  onButtonPressed?(e: { id: string; templateId: string }): void;
  buttons?: NowPlayingButton[];
}

export class NowPlayingTemplate extends Template<NowPlayingTemplateConfig> {
  public get type(): string {
    return 'nowplaying';
  }

  get eventMap() {
    return {
      albumArtistButtonPressed: 'onAlbumArtistButtonPressed',
      upNextButtonPressed: 'onUpNextButtonPressed',
      buttonPressed: 'onButtonPressed',
    };
  }
}
