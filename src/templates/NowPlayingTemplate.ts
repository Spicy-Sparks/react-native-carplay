import { Template, TemplateConfig } from './Template';

export type NowPlayingButton = {
  id: string;
  imageName: string;
  selected: boolean;
};

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
