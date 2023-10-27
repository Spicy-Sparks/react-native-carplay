import { ImageSourcePropType } from 'react-native';

/**
 * A list item that appears in a list template.
 */
export interface ListItem {
  /**
   * 
   * The item id.
   */
  id?: string;
  /**
   * The primary text displayed in the list item cell.
   */
  text: string;
  /**
   * Extra text displayed below the primary text in the list item cell.
   */
  detailText?: string;
  /**
   * The image displayed on the leading edge of the list item cell.
   */
  image?: ImageSourcePropType;
  /**
   * The image from file system displayed on the leading edge of the list item cell.
   */
  imgUrl?: string;
  /**
   * The sub items arranged in a row.
   */
  rowItems?: ListItem[];
  /**
   * A Boolean value indicating whether the list item cell shows a disclosure indicator on the trailing edge of the list item cell.
   */
  showsDisclosureIndicator?: boolean;
  /**
   * Is Playing flag.
   */
  isPlaying?: boolean;
  /**
   * Is Artist flag.
   */
  isArtist?: boolean
}
