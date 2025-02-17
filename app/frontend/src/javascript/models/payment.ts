import { Reservation } from './reservation';
import { SubscriptionRequest } from './subscription';

export interface PaymentConfirmation {
  requires_action?: boolean,
  payment_intent_client_secret?: string,
  type?: 'payment' | 'subscription',
  subscription_id?: string,
  success?: boolean,
  error?: {
    statusText: string
  }
}

export interface IntentConfirmation {
  client_secret: string
}

export enum PaymentMethod {
  Card = 'card',
  Check = 'check',
  Transfer = 'transfer',
  Other = ''
}

export type CartItem = { reservation: Reservation }|
  { subscription: SubscriptionRequest }|
  { prepaid_pack: { id: number } }|
  { free_extension: { end_at: Date } };

export interface ShoppingCart {
  customer_id: number,
  // WARNING: items ordering matters! The first item in the array will be considered as the main item
  items: Array<CartItem>,
  coupon_code?: string,
  payment_schedule?: boolean,
  payment_method: PaymentMethod
}

export interface UpdateCardResponse {
  updated: boolean,
  error?: string
}
