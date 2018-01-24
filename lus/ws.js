// <script src='/assets/js/ws.js'></script>

// Using https://github.com/Olical/EventEmitter
!function(e){"use strict";function t(){}function n(e,t){for(var n=e.length;n--;)if(e[n].listener===t)return n;return-1}function r(e){return function(){return this[e].apply(this,arguments)}}function i(e){return"function"==typeof e||e instanceof RegExp||!(!e||"object"!=typeof e)&&i(e.listener)}var s=t.prototype,o=e.EventEmitter;s.getListeners=function(e){var t,n,r=this._getEvents();if(e instanceof RegExp){t={};for(n in r)r.hasOwnProperty(n)&&e.test(n)&&(t[n]=r[n])}else t=r[e]||(r[e]=[]);return t},s.flattenListeners=function(e){var t,n=[];for(t=0;t<e.length;t+=1)n.push(e[t].listener);return n},s.getListenersAsObject=function(e){var t,n=this.getListeners(e);return n instanceof Array&&(t={},t[e]=n),t||n},s.addListener=function(e,t){if(!i(t))throw new TypeError("listener must be a function");var r,s=this.getListenersAsObject(e),o="object"==typeof t;for(r in s)s.hasOwnProperty(r)&&n(s[r],t)===-1&&s[r].push(o?t:{listener:t,once:!1});return this},s.on=r("addListener"),s.addOnceListener=function(e,t){return this.addListener(e,{listener:t,once:!0})},s.once=r("addOnceListener"),s.defineEvent=function(e){return this.getListeners(e),this},s.defineEvents=function(e){for(var t=0;t<e.length;t+=1)this.defineEvent(e[t]);return this},s.removeListener=function(e,t){var r,i,s=this.getListenersAsObject(e);for(i in s)s.hasOwnProperty(i)&&(r=n(s[i],t),r!==-1&&s[i].splice(r,1));return this},s.off=r("removeListener"),s.addListeners=function(e,t){return this.manipulateListeners(!1,e,t)},s.removeListeners=function(e,t){return this.manipulateListeners(!0,e,t)},s.manipulateListeners=function(e,t,n){var r,i,s=e?this.removeListener:this.addListener,o=e?this.removeListeners:this.addListeners;if("object"!=typeof t||t instanceof RegExp)for(r=n.length;r--;)s.call(this,t,n[r]);else for(r in t)t.hasOwnProperty(r)&&(i=t[r])&&("function"==typeof i?s.call(this,r,i):o.call(this,r,i));return this},s.removeEvent=function(e){var t,n=typeof e,r=this._getEvents();if("string"===n)delete r[e];else if(e instanceof RegExp)for(t in r)r.hasOwnProperty(t)&&e.test(t)&&delete r[t];else delete this._events;return this},s.removeAllListeners=r("removeEvent"),s.emitEvent=function(e,t){var n,r,i,s,o,u=this.getListenersAsObject(e);for(s in u)if(u.hasOwnProperty(s))for(n=u[s].slice(0),i=0;i<n.length;i++)r=n[i],r.once===!0&&this.removeListener(e,r.listener),o=r.listener.apply(this,t||[]),o===this._getOnceReturnValue()&&this.removeListener(e,r.listener);return this},s.trigger=r("emitEvent"),s.emit=function(e){var t=Array.prototype.slice.call(arguments,1);return this.emitEvent(e,t)},s.setOnceReturnValue=function(e){return this._onceReturnValue=e,this},s._getOnceReturnValue=function(){return!this.hasOwnProperty("_onceReturnValue")||this._onceReturnValue},s._getEvents=function(){return this._events||(this._events={})},t.noConflict=function(){return e.EventEmitter=o,t},"function"==typeof define&&define.amd?define(function(){return t}):"object"==typeof module&&module.exports?module.exports=t:e.EventEmitter=t}(this||{});

// Using https://github.com/Olical/Heir
(function (name, root, factory) {
    if (typeof define === 'function' && define.amd) {
        define(factory);
    }
    else if (typeof exports === 'object') {
        module.exports = factory();
    }
    else {
        root[name] = factory();
    }
}('heir', this, function () {
    /*global define,module*/
    'use strict';

    var heir = {
        inherit: function inherit(destination, source, addSuper) {
            var proto = destination.prototype = heir.createObject(source.prototype);
            proto.constructor = destination;

            if (addSuper || typeof addSuper === 'undefined') {
                destination._super = source.prototype;
            }
        },

        createObject: Object.create || function createObject(source) {
            var Host = function () {};
            Host.prototype = source;
            return new Host();
        },

        mixin: function mixin(destination, source) {
            return heir.merge(destination.prototype, source);
        },

        merge: function merge(destination, source) {
            var key;

            for (key in source) {
                if (heir.hasOwn(source, key)) {
                    destination[key] = source[key];
                }
            }
        },

        hasOwn: function hasOwn(object, key) {
            return Object.prototype.hasOwnProperty.call(object, key);
        }
    };

    return heir;
}));

Object.inherit = function(child, parent) {
	heir.inherit(child, parent);
}

var WS = {};
function _WSEvent(){}
Object.inherit(_WSEvent, EventEmitter);
WS.new = function() {
	var o = new _WSEvent();

	o.connect = function(options, onConnect, onMessage, onClose, onError) {
		o._host = options.host || 'ws://127.0.0.1:8080';
		o._enc = options.enc;
		o._ws = new WebSocket(options.host);
		o._ws.onopen = function(e) {
			onConnect(e);
		};
		o._ws.onmessage = function(e) {
			var data = e.data;
			if (o._enc == 'json') {
				data = JSON.parse(e.data);
				if (data && data._E) {
					o.emit(data._E, data._A);
				}
			}
			onMessage(data);
		};
		o._ws.onclose = function(e) {
			onClose(e);
		};
		o._ws.onerror = function(e) {
			onError(e);
		};
	};

	o.send = function(data) {
		if (o._enc == 'json') {
			data = JSON.stringify(data);
		}
		o._ws.send(data);
	}

	o.Emit = function(event, args) {
		if (o._enc != 'json') {
			return;
		}
		var data = JSON.stringify({_E:event, _A:args});
		o._ws.send(data);
	}

	return o;
}