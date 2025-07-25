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
import type { User } from './User';
import {
    UserFromJSON,
    UserFromJSONTyped,
    UserToJSON,
    UserToJSONTyped,
} from './User';
import type { ShoppingCartItem } from './ShoppingCartItem';
import {
    ShoppingCartItemFromJSON,
    ShoppingCartItemFromJSONTyped,
    ShoppingCartItemToJSON,
    ShoppingCartItemToJSONTyped,
} from './ShoppingCartItem';

/**
 * 
 * @export
 * @interface ShoppingCart
 */
export interface ShoppingCart {
    /**
     * 
     * @type {number}
     * @memberof ShoppingCart
     */
    id?: number;
    /**
     * 
     * @type {number}
     * @memberof ShoppingCart
     */
    userId?: number;
    /**
     * 
     * @type {Date}
     * @memberof ShoppingCart
     */
    createdAt?: Date;
    /**
     * 
     * @type {Date}
     * @memberof ShoppingCart
     */
    updatedAt?: Date | null;
    /**
     * 
     * @type {boolean}
     * @memberof ShoppingCart
     */
    isActive?: boolean;
    /**
     * 
     * @type {User}
     * @memberof ShoppingCart
     */
    user?: User;
    /**
     * 
     * @type {Array<ShoppingCartItem>}
     * @memberof ShoppingCart
     */
    items?: Array<ShoppingCartItem> | null;
}

/**
 * Check if a given object implements the ShoppingCart interface.
 */
export function instanceOfShoppingCart(value: object): value is ShoppingCart {
    return true;
}

export function ShoppingCartFromJSON(json: any): ShoppingCart {
    return ShoppingCartFromJSONTyped(json, false);
}

export function ShoppingCartFromJSONTyped(json: any, ignoreDiscriminator: boolean): ShoppingCart {
    if (json == null) {
        return json;
    }
    return {
        
        'id': json['id'] == null ? undefined : json['id'],
        'userId': json['userId'] == null ? undefined : json['userId'],
        'createdAt': json['createdAt'] == null ? undefined : (new Date(json['createdAt'])),
        'updatedAt': json['updatedAt'] == null ? undefined : (new Date(json['updatedAt'])),
        'isActive': json['isActive'] == null ? undefined : json['isActive'],
        'user': json['user'] == null ? undefined : UserFromJSON(json['user']),
        'items': json['items'] == null ? undefined : ((json['items'] as Array<any>).map(ShoppingCartItemFromJSON)),
    };
}

export function ShoppingCartToJSON(json: any): ShoppingCart {
    return ShoppingCartToJSONTyped(json, false);
}

export function ShoppingCartToJSONTyped(value?: ShoppingCart | null, ignoreDiscriminator: boolean = false): any {
    if (value == null) {
        return value;
    }

    return {
        
        'id': value['id'],
        'userId': value['userId'],
        'createdAt': value['createdAt'] == null ? undefined : ((value['createdAt']).toISOString()),
        'updatedAt': value['updatedAt'] === null ? null : ((value['updatedAt'] as any)?.toISOString()),
        'isActive': value['isActive'],
        'user': UserToJSON(value['user']),
        'items': value['items'] == null ? undefined : ((value['items'] as Array<any>).map(ShoppingCartItemToJSON)),
    };
}

