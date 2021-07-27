import { createElement } from 'lwc';
import SimpliUIListViews from 'c/simpliUIListViews';
import { subscribe, unsubscribe, publish, APPLICATION_SCOPE, MessageContext } from 'lightning/messageService';

describe('c-simpli-u-i-list-views', () => {
    afterEach(() => {
        // The jsdom instance is shared across test cases in a single file so reset the DOM
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    test('Initialization', () => {
        const element = createElement('c-simpli-u-i-list-views', {
            is: SimpliUIListViews
        });
        document.body.appendChild(element);
        expect(1).toBe(1);
    });
});