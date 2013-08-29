/*
    This file defines some common functions that are useful for WebGL.
    Also defines the class AffineTransform2D, which represents affine
    transfomations in 2D.  It ensures that requestAnimation Frame() is
    available, and it defines an Animator class to help with animation.
*/

/**
 * Creates a program for use in the WebGL context gl, and returns the
 * identifier for that program.  If an error occurs while compiling or
 * linking the program, an exception of type String is thrown.  The
 * string contains the compilation or linking error.  If no error occurs,
 * the program identifier is the return value of the function.
 */
function createProgram(gl, vertexShaderSource, fragmentShaderSource) {
   var vsh = gl.createShader( gl.VERTEX_SHADER );
   gl.shaderSource(vsh,vertexShaderSource);
   gl.compileShader(vsh);
   if ( ! gl.getShaderParameter(vsh, gl.COMPILE_STATUS) ) {
      throw "Error in vertex shader:  " + gl.getShaderInfoLog(vsh);
   }
   var fsh = gl.createShader( gl.FRAGMENT_SHADER );
   gl.shaderSource(fsh, fragmentShaderSource);
   gl.compileShader(fsh);
   if ( ! gl.getShaderParameter(fsh, gl.COMPILE_STATUS) ) {
      throw "Error in fragment shader:  " + gl.getShaderInfoLog(fsh);
   }
   var prog = gl.createProgram();
   gl.attachShader(prog,vsh);
   gl.attachShader(prog, fsh);
   gl.linkProgram(prog);
   if ( ! gl.getProgramParameter( prog, gl.LINK_STATUS) ) {
      throw "Link error in program:  " + gl.getProgramInfoLog(prog);
   }
   return prog;
}

/**
 * Get all the text content from an HTML element (including
 * any text in contained elements.)  The text is returned
 * as a string.
 * @param elem either a string giving the id of an element, or
 *    the elemnent node itself.  If neither of these is the
 *    case, an exception of type string is thrown.
 */
function getElementText(elem) {
    if (typeof(elem) == "string")
        elem = document.getElementById(elem);
    if (!elem.firstChild)
        throw "argument to getTextFromElement is not an element or the id of an element";
    var str = "";
    var node = elem.firstChild;
    while (node) {
        if (node.nodeType == 3) // text node
            str += node.nodeValue;
        else if (node.nodeType == 1) // element
            str += getTextFromElement(node);
        node = node.nextSibling;
    }
    return str;
}

/**
 * Create a WebGL drawing context for a canvas element.  The parameter can
 * be either a string that is the id of a canvas element, or it can be the
 * canvas element itself.
 */
function createWebGLContext(canvas) {
   var c;
   if ( ! canvas )
      throw "Canvas required";
   if (typeof canvas == "string")
      c = document.getElementById(canvas);
   else
      c = canvas;
   if ( ! c.getContext )
      throw "No legal canvas provided";
   var gl = c.getContext("webgl", { depth: false, antialias: true } );
   if ( ! gl ) {
      gl = c.getContext("experimental-webgl", { depth: false, antialias: true } );
   }  
   if ( ! gl )
      throw "Can't create WebGLContext";
   return gl;
}

/**
 * A convenience function, used during debugging, which checks whether a
 * GL error has occured in the drawing context, gl.  The method returns null
 * if no error has occurred, and retuns a string that describes the error if
 * one has occurred.  (The string is a little more useful than the native GL
 * error code.)  Note that once an error occurs, GL retains that error until
 * gl.getError() is called, so you can't assume that the error occurred on
 * the error occurred in the line that precedes the call to this function.
 */
function checkGLError(gl) {
      var e = gl.getError();
      if ( e == gl.NO_ERROR )
         return null;
      else if ( e == gl.INVALID_ENUM )
         return "Invalid constant";
      else if ( e == gl.INVALID_VALUE )
         return "Numeric argument out of range.";
      else if ( e == gl.INVALID_OPERATION )
         return "Invalid operation for current state.";
      else if ( e == gl.OUT_OF_MEMORY )
         return "Out of memory.";
      else
         return "??? Unknown error ???";
}

/**
 * The following statement makes sure that requestAnimationFrame
 * is available as a fuction, using a browser-specific version if 
 * available or falling back to setTimeout if necessary.  Call
 * requestAnimationFrame(callbackFunction) to set up a call to
 * callbackFunction.  callbackFunction is called with a parameter
 * that gives the current time.  
 */
window.requestAnimationFrame = 
    window.requestAnimationFrame ||
    window.mozRequestAnimationFrame ||
    window.webkitRequestAnimationFrame ||
    window.msRequestAnimationFrame ||
    function (callback) {
        setTimeout(function() { callback(Date.now()); },  1000/60);
    }

/**
 * This constructor defines the class Animator.  An Animator runs
 * an animation by calling a callback function over and over again.
 * The constructor requires one parameter, which must be a callback
 * function.  Ordinarily, this should be a function with one parameter,
 * which will represent the number of milliseconds for which the
 * animation has beeen running.  If the animation is paused, by
 * calling the stop() method, and then restarted, the the time for
 * which the animation was paused is NOT included in the parameter
 * to callback.  (callback is actually called with two parameters,
 * where the second parameter is the number of millisconds since
 * the animation was started; if the animation was never paused,
 * then the two parameters are the same.)
 *    After creating an Animation, you must call its start() method
 * to start the animation.  Call the stop() method to pause the
 * animation.  As an alternative to start/stop, you can call
 * setAnimating(x) with x = true/false.  The method isAnimating
 * returns true if the animation is running, false if it is paused.
 *    The constructor throws an exception of type string if the
 * first parameter is absent or is not a function.  (Extra 
 * parameters are ignored.)
 *    (The animation uses requestAnimationFrame if available;
 * otherwise, it uses setTimeout.)
 */
function Animator(callback) {
   if ( ! callback || ! (typeof callback == "function") ) {
      throw "Callback function required for Animator";
   }
   var animating = false;
   var animationStartTime;
   var timePaused = 0;
   var pauseStart;
   var reqAnimFrm = window.requestAnimationFrame || 
        window.mozRequestAnimationFrame ||
        window.webkitRequestAnimationFrame ||
        window.msRequestAnimationFrame ||
        function (frame) {
           setTimeout(function() { frame(Date.now()); },  1000/60);
        }
   function doFrm( time ) {
      if (!animating) {
          pauseStart = time;
      }
      else {
          if (!animationStartTime)
             animationStartTime = time;
          if (pauseStart) {
             timePaused += time - pauseStart;
             pauseStart = undefined;
          }
          var wallTime = time - animationStartTime;   // Time since start of animation.
          var animationTime = wallTime - timePaused;  // Time during whigh animation was running (not counting pauses).
          callback(animationTime, wallTime);
          reqAnimFrm(doFrm);
      }
   }
   this.start = function() {
      if (!animating) {
         animating = true;
         reqAnimFrm(doFrm);
      }
   }
   this.stop = function() {
      animating = false;
   }
   this.isAnimating = function() {
      return animating;
   }
   this.setAnimating = function(animate) {
      if (animate)
         this.start();
      else
         this.stop();
   }
}


/**
 * The class AffineTransform2D represents an affine transformin 2D.  A constructor
 * with no arguemnts creates the identity transform.  An object trns of type
 * AffineTransform includes methods like trns.rotate(d) and trns.translate(dx,dy)
 * for modifying the transform (by multiplying it on the right).  The method
 * trns.getMat3() returns the matrix of the transform in a form suitable for
 * use as a parameter to gl.uniformMatrix3fv().  A transform object maintains
 * an internal stack to make it possible to save/restore the current transform
 * by calling trns.push() and trns.pop().
 */
function AffineTransform2D() {
   if (arguments.length == 0) {
       this.a = 1;
       this.b = 0;
       this.c = 0;
       this.d = 1;
       this.e = 0;
       this.f = 0;
   }
   else if (arguments.length == 1 && arguments[0] instanceof AffineTransform2D) {
       this.a = arguments[0].a;
       this.b = arguments[0].b;
       this.c = arguments[0].c;
       this.d = arguments[0].d;
       this.e = arguments[0].e;
       this.f = arguments[0].f;
   }
   else {
      var src = (arguments.length == 1 && arguments[0] instanceof Array) ? arguments[0] : arguments;
      this.a = src.length > 0 ? Number(src[0]) : 1;
      this.b = src.length > 1 ? Number(src[1]) : 0;
      this.c = src.length > 2 ? Number(src[2]) : 0;
      this.d = src.length > 3 ? Number(src[3]) : 1;
      this.e = src.length > 4 ? Number(src[4]) : 0;
      this.f = src.length > 5 ? Number(src[5]) : 0;
   }
   var stack = new Array();
   this.push = function() {
      stack.push( [this.a, this.b, this.c, this.d, this.e, this.f ]);
   }
   this.pop = function() {
      var x = stack.pop();
      this.a = x[0];
      this.b = x[1];
      this.c = x[2];
      this.d = x[3];
      this.e = x[4];
      this.f = x[5];
   }
}
AffineTransform2D.prototype.getMat3 = function() {
   return [ this.a, this.b, 0, this.c, this.d, 0, this.e, this.f, 1 ];
}
AffineTransform2D.prototype.translate = function( /* Number */ dx, /* Number */ dy) {
   this.e += this.a*dx + this.c*dy;
   this.f += this.b*dx + this.d*dy;
   return this;
}
AffineTransform2D.prototype.rotate = function( /* Number */ degrees ) {
   var sin = Math.sin( degrees * Math.PI / 180);
   var cos = Math.cos( degrees * Math.PI / 180); 
   var temp = this.a*cos + this.c*sin;
   this.c = -this.a*sin + this.c*cos;
   this.a = temp;
   temp = this.b*cos + this.d*sin;
   this.d = -this.b*sin + this.d*cos;
   this.b = temp;   
   return this;
}
AffineTransform2D.prototype.rotateAbout = function( /* Number */ x, /* Number */ y,  /* Number */ degrees ) {
   this.translate(x,y);
   this.rotate(degrees);
   this.translate(-x,-y);
   return this;
}
AffineTransform2D.prototype.scale = function( /* Number */ sx, /* optional Number */ sy ) {
   if ( ! sy )
      sy = sx;
   this.a = sx*this.a;
   this.b = sx*this.b;
   this.c = sy*this.c;
   this.d = sy*this.d;
   return this;
}
AffineTransform2D.prototype.scaleAbout = function( /* Number */ x, /* Number */ y, /* Number */ sx, /* optional Number */ sy) {
   this.translate(x,y);
   this.scale(sx,sy);
   this.translate(-x,-y);
   return this;
}
AffineTransform2D.prototype.xshear = function( /* Number */ shear) {
   this.c += this.a*shear;  
   this.d += this.b*shear;
}
AffineTransform2D.prototype.times = function( /* AffineTransform2D */ that ) {
   var a = this.a*that.a + this.c*that.b;
   var b = this.b*that.a + this.d*that.b;
   var c = this.a*that.c + this.c*that.d;
   var d = this.b*that.c + this.d*that.d;
   var e = this.a*that.e + this.c*that.f + this.e;
   var f = this.b*that.e + this.d*that.f + this.f;
   this.a = a;
   this.b = b;
   this.c = c;
   this.d = d;
   this.e = e;
   this.f = f;
   return this;
}
AffineTransform2D.prototype.toString = function() {
   return "AffineTransform2D(" + this.a + "," + this.b + "," + this.c + "," + this.d + "," + this.e + "," + this.f + ")";
}
