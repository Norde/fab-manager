import { TDateISO } from '../typings/date-iso';
import { ApiFilter } from './api';

export interface UserPackIndexFilter extends ApiFilter {
  user_id?: number,
  priceable_type: string,
  priceable_id: number
}

export interface UserPack {
  minutes_used: number,
  expires_at: TDateISO,
  prepaid_pack: {
    minutes: number,
  }
}
