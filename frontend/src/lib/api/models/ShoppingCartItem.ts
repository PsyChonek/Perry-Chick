/* tslint:disable */
/* eslint-disable */
/**
 * Perry Chick API
 * No description provided (generated by Openapi Generator https://github.com/openapitools/openapi-generator)
 *
 * The version of the OpenAPI document: v1
 * 
 *
 * NOTE: This class is auto generated by OpenAPI Generator (https://openapi-generator.tech).
 * https://openapi-generator.tech
 * Do not edit the class manually.
 */

import { mapValues } from '../runtime';
import type { StoreItem } from './StoreItem';
import {
    StoreItemFromJSON,
    StoreItemFromJSONTyped,
    StoreItemToJSON,
    StoreItemToJSONTyped,
} from './StoreItem';

/**
 * 
 * @export
 * @interface ShoppingCartItem
 */
export interface ShoppingCartItem {
    /**
     * 
     * @type {number}
     * @memberof ShoppingCartItem
     */
    id?: number;
    /**
     * 
     * @type {number}
     * @memberof ShoppingCartItem
     */
    shoppingCartId?: number;
    /**
     * 
     * @type {number}
     * @memberof ShoppingCartItem
     */
    storeItemId?: number;
    /**
     * 
     * @type {number}
     * @memberof ShoppingCartItem
     */
    quantity?: number;
    /**
     * 
     * @type {Date}
     * @memberof ShoppingCartItem
     */
    createdAt?: Date;
    /**
     * 
     * @type {Date}
     * @memberof ShoppingCartItem
     */
    updatedAt?: Date | null;
    /**
     * 
     * @type {boolean}
     * @memberof ShoppingCartItem
     */
    isActive?: boolean;
    /**
     * 
     * @type {StoreItem}
     * @memberof ShoppingCartItem
     */
    storeItem?: StoreItem;
}

/**
 * Check if a given object implements the ShoppingCartItem interface.
 */
export function instanceOfShoppingCartItem(value: object): value is ShoppingCartItem {
    return true;
}

export function ShoppingCartItemFromJSON(json: any): ShoppingCartItem {
    return ShoppingCartItemFromJSONTyped(json, false);
}

export function ShoppingCartItemFromJSONTyped(json: any, ignoreDiscriminator: boolean): ShoppingCartItem {
    if (json == null) {
        return json;
    }
    return {
        
        'id': json['id'] == null ? undefined : json['id'],
        'shoppingCartId': json['shoppingCartId'] == null ? undefined : json['shoppingCartId'],
        'storeItemId': json['storeItemId'] == null ? undefined : json['storeItemId'],
        'quantity': json['quantity'] == null ? undefined : json['quantity'],
        'createdAt': json['createdAt'] == null ? undefined : (new Date(json['createdAt'])),
        'updatedAt': json['updatedAt'] == null ? undefined : (new Date(json['updatedAt'])),
        'isActive': json['isActive'] == null ? undefined : json['isActive'],
        'storeItem': json['storeItem'] == null ? undefined : StoreItemFromJSON(json['storeItem']),
    };
}

export function ShoppingCartItemToJSON(json: any): ShoppingCartItem {
    return ShoppingCartItemToJSONTyped(json, false);
}

export function ShoppingCartItemToJSONTyped(value?: ShoppingCartItem | null, ignoreDiscriminator: boolean = false): any {
    if (value == null) {
        return value;
    }

    return {
        
        'id': value['id'],
        'shoppingCartId': value['shoppingCartId'],
        'storeItemId': value['storeItemId'],
        'quantity': value['quantity'],
        'createdAt': value['createdAt'] == null ? undefined : ((value['createdAt']).toISOString()),
        'updatedAt': value['updatedAt'] === null ? null : ((value['updatedAt'] as any)?.toISOString()),
        'isActive': value['isActive'],
        'storeItem': StoreItemToJSON(value['storeItem']),
    };
}

