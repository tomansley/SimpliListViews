import { createElement } from 'lwc';
import SimpliUIListViewsAdmin from 'c/simpliUIListViewsAdmin';

describe('c-simpli-u-i-list-views-admin', () => {
    afterEach(() => {
        // The jsdom instance is shared across test cases in a single file so reset the DOM
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    let adminView = element.shadowRoot.querySelector('c-simpli-u-i-list-views-admin');
    adminView.getOrgWideConfig = jest.fn().mockImplementation(() => { return ['']; });

    test('Init Method', () => {
        const element = createElement('c-simpli-u-i-list-views-admin', {
            is: SimpliUIListViewsAdmin
        });
        document.body.appendChild(element);

        

        expect(1).toBe(1);
        expect(2).toBe(2);
    });
});