import { Platform } from 'react-native';
import { CarPlay } from '../CarPlay';

export interface RequestEvent {
  templateId: string;
  requestId?: string;
}

// Older binaries have one shared slot. Ignore stale replies across templates.
let legacySearch = 0;
let legacySelection = 0;

export function searchCompletion(event: RequestEvent): (items: unknown[]) => void {
  const generation = ++legacySearch;
  return items => {
    if (Platform.OS !== 'ios') return;
    if (event.requestId && CarPlay.bridge.reactToUpdatedSearchTextForRequest) {
      CarPlay.bridge.reactToUpdatedSearchTextForRequest(items, event.templateId, event.requestId);
    } else if (generation === legacySearch) {
      CarPlay.bridge.reactToUpdatedSearchText(items, event.templateId);
    }
  };
}

export function selectionCompletion(event: RequestEvent): () => void {
  const generation = ++legacySelection;
  return () => {
    if (Platform.OS !== 'ios') return;
    if (event.requestId && CarPlay.bridge.reactToSelectedResultForRequest) {
      CarPlay.bridge.reactToSelectedResultForRequest(event.templateId, event.requestId);
    } else if (generation === legacySelection) {
      CarPlay.bridge.reactToSelectedResult(true);
    }
  };
}
