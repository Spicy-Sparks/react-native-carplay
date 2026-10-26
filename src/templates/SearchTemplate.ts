import { Image } from 'react-native';
import { RequestEvent, searchCompletion, selectionCompletion } from './requestCompletion';
import { ListItem } from '../interfaces/ListItem';
import { BaseEvent, Template, TemplateConfig } from './Template';

export interface SearchTemplateConfig extends TemplateConfig {
  /**
   * Fired when search input is changed.
   * Must return list of items to show.
   * @param query Search query
   */
  onSearch?(query: string): Promise<ListItem[]>;
  /**
   * Fired when result item is selected.
   * Spinner shows by default.
   * When the returned promise is resolved the spinner will hide.
   * @param item Object with the selected index
   */
  onItemSelect?(item: { index: number }): Promise<void>;
  /**
   * Fired when search button is pressed
   */
  onSearchButtonPressed?(e: BaseEvent): void;
}

export class SearchTemplate extends Template<SearchTemplateConfig> {
  private searchGeneration = 0;

  public dispose(): void {
    this.searchGeneration++;
    super.dispose();
  }

  public get type(): string {
    return 'search';
  }

  get eventMap() {
    return {
      searchButtonPressed: 'onSearchButtonPressed',
    };
  }

  constructor(public config: SearchTemplateConfig) {
    // parse out any images in the results

    super(config);

    this.addListener('didDisappear', (e: BaseEvent) => {
      if (e.templateId === this.id) this.searchGeneration++;
    });
    this.addListener('updatedSearchText', (e: RequestEvent & { searchText: string }) => {
      if (e.templateId !== this.id || this.disposed) return;
      const generation = ++this.searchGeneration;
      const complete = searchCompletion(e);
      void Promise.resolve()
        .then(() => config.onSearch?.(e.searchText) ?? [])
        .then(result => {
          if (this.disposed || generation !== this.searchGeneration) return complete([]);
          complete(
            result.map(item => ({
              ...item,
              image: item.image ? Image.resolveAssetSource(item.image) : undefined,
            })),
          );
        })
        .catch(error => {
          console.error('CarPlay search failed', error);
          complete([]);
        });
    });
    this.addListener('selectedResult', (e: RequestEvent & { index: number }) => {
      if (e.templateId !== this.id || this.disposed) return;
      const complete = selectionCompletion(e);
      void Promise.resolve()
        .then(() => config.onItemSelect?.(e))
        .catch(error => {
          console.error('CarPlay search selection failed', error);
        })
        .then(complete);
    });
  }
}
