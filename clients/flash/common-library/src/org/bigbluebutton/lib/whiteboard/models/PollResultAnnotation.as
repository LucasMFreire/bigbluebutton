/**
 * BigBlueButton open source conferencing system - http://www.bigbluebutton.org/
 * 
 * Copyright (c) 2012 BigBlueButton Inc. and by respective authors (see below).
 *
 * This program is free software; you can redistribute it and/or modify it under the
 * terms of the GNU Lesser General Public License as published by the Free Software
 * Foundation; either version 3.0 of the License, or (at your option) any later
 * version.
 * 
 * BigBlueButton is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
 * PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License along
 * with BigBlueButton; if not, see <http://www.gnu.org/licenses/>.
 *
 */

package org.bigbluebutton.lib.whiteboard.models
{
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	
	import mx.collections.ArrayCollection;
	import mx.core.IVisualElement;
	import mx.core.UIComponent;
	import mx.graphics.SolidColor;
	import mx.graphics.SolidColorStroke;
	import mx.resources.ResourceManager;
	
	import org.bigbluebutton.lib.whiteboard.views.IWhiteboardCanvas;
	
	import spark.primitives.Rect;
	
	public class PollResultAnnotation extends Annotation {
		
		//private const h:uint = 100;
		//private const w:uint = 280;
		private const marginFill:uint = 0xFFFFFF;
		private const bgFill:uint = 0xFFFFFF;
		private const colFill:uint = 0x333333;
		private const margin:Number = 0.025;
		private const vPaddingPercent:Number = 0.25;
		private const hPaddingPercent:Number = 0.1;
		private const labelWidthPercent:Number = 0.3;
		
		private var _data:Array;
		private var _textFields:Array;
		
		private var _points:Array = [];
		
		private var _result:Array = [];
		
		private var _rectangle:Rect;
		
		private var _relX:Number;
		
		private var _relY:Number;
		
		private var _pollContainer:UIComponent;
		
		private var _pollRects:ArrayCollection;
		
		public function PollResultAnnotation(type:String, anID:String, whiteboardID:String, status:String,  points:Array, result:Array) {
			super(type, anID, whiteboardID, status, color);
			
			_points = points;
			_result = result;
			
			_textFields = new Array();
			_pollContainer = new UIComponent();
			_pollRects = new ArrayCollection();
			data = null;
		}
		
		public function set data(d:Array):void {
			_data = d;
		}
		
		public function get data():Array {
			return _data;
		}
		
		public function get points():Array {
			return _points;
		}
		
		public function get result():Array {
			return _result;
		}
		
		private function makeTextFields(num:int, canvas:IWhiteboardCanvas):void {
			if (num > _textFields.length) {
				var textField:TextField;
				for (var i:int=_textFields.length; i < num; i++) {
					textField = new TextField();
					_textFields.push(textField);
				}
			} else if (num < _textFields.length) {
				for (var j:int=_textFields.length; i > num; i--) {
					_textFields.pop();
				}
			}
		}
		
		private function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number, canvas:IWhiteboardCanvas):void {
			
			_pollContainer.removeChildren();
			
			for (var i:int = _pollRects.length - 1; i >= 0; i--) {
				canvas.removeElement(_pollRects[i]);
				_pollRects.removeItemAt(i);
			}
			
			if (_data != null && _data.length > 0) {
				
				var	rectangle = new Rect();
				rectangle.stroke = new SolidColorStroke(uint(marginFill), 0);
				rectangle.fill =  new SolidColor(marginFill);
				rectangle.x = _relX;
				rectangle.y = _relY;
				rectangle.width = unscaledWidth;
				rectangle.height = unscaledHeight;
				canvas.addElement(rectangle);
				_pollRects.addItem(rectangle);
				
				var calcMargin:int = unscaledWidth * margin;
				var graphX:int = calcMargin + _relX;
				var graphY:int = calcMargin + _relY;
				var graphWidth:int = unscaledWidth - calcMargin*2;
				var graphHeight:int = unscaledHeight - calcMargin*2;
				
				var	rectangle = new Rect();
				rectangle.stroke = new SolidColorStroke(uint(colFill), 2);
				rectangle.fill = new SolidColor(bgFill);
				rectangle.x = calcMargin + _relX;
				rectangle.y = calcMargin + _relY;
				rectangle.width = graphWidth;
				rectangle.height = graphHeight;
				canvas.addElement(rectangle);
				_pollRects.addItem(rectangle);
				
				var vpadding:int = (graphHeight*vPaddingPercent)/(_data.length+1);
				var hpadding:int = (graphWidth*hPaddingPercent)/(4);
				
				var actualRH:Number = (graphHeight-vpadding*(_data.length+1)) / _data.length;
				// Current problem is that the rowHeight is truncated. It would be nice if the extra pixels 
				// could be distributed for a more even look.
				var avgRowHeight:int = (graphHeight-vpadding*(_data.length+1)) / _data.length;
				var extraVPixels:int = graphHeight - (_data.length * (avgRowHeight+vpadding) + vpadding);
				var largestVal:int = -1;
				var totalCount:Number = 0;
				//find largest value
				for (var i:int=0; i<_data.length; i++) {
					if (_data[i].v > largestVal) largestVal = _data[i].v;
					totalCount += _data[i].v;
				}
				
				var currTFIdx:int = 0;
				var answerText:TextField;
				var percentText:TextField;
				var answerArray:Array = new Array();
				var percentArray:Array = new Array();
				var minFontSize:int = 30;
				var currFontSize:int;
				
				//var startingLabelWidth:Number = Math.min(labelWidthPercent*graphWidth, labelMaxWidthInPixels);
				var startingLabelWidth:Number = labelWidthPercent*graphWidth;
				
				for (var j:int=0, vp:int=extraVPixels, ry:int=graphY, curRowHeight:int=0; j<_data.length; j++) {
					ry += Math.round(curRowHeight/2)+vpadding; // add the last row's height plus padding
					
					curRowHeight = avgRowHeight;
					if (j%2==0 && vp > 0) {
						curRowHeight += 1;
						vp--;
					}
					ry += curRowHeight/2;
					
					//ry += curRowHeight * (j+0.5) + vpadding*(j+1);
					// add row label
					answerText = _textFields[currTFIdx++];
					answerText.text = _data[j].a;
					answerText.width = startingLabelWidth;
					answerText.height = curRowHeight;
					answerText.selectable = false;
					_pollContainer.addChild(answerText);
					answerArray.push(answerText);
					currFontSize = findFontSize(answerText, minFontSize);
					if (currFontSize < minFontSize) minFontSize = currFontSize;
					//rowText.height = rowText.textHeight;
					answerText.x = graphX + hpadding;
					//rowText.y = ry-rowText.height/2;
					
					// add percentage
					percentText = _textFields[currTFIdx++];;// new TextField();
					var percentNum:Number = (totalCount == 0 ? 0 : ((_data[j].v/totalCount)*100));
					percentText.text = Math.round(percentNum).toString() + "%";
					percentText.width = startingLabelWidth;
					percentText.height = curRowHeight;
					percentText.selectable = false;
					var container:UIComponent = new UIComponent();
					_pollContainer.addChild(percentText);
					percentArray.push(percentText);
					currFontSize = findFontSize(percentText, minFontSize);
					if (currFontSize < minFontSize) minFontSize = currFontSize;
					//percentText.height = percentText.textHeight;
					//percentText.x = graphWidth-percentStartWidth/2-percentText.width/2;
					//percentText.y = ry-percentText.height/2;
				}
				
				var maxAnswerWidth:int = 0;
				var maxPercentWidth:int = 0;
				
				for (j=0, vp=extraVPixels, ry=graphY, curRowHeight=0; j<_data.length; j++) {
					ry += Math.round(curRowHeight/2)+vpadding; // add the last row's height plus padding
					
					curRowHeight = avgRowHeight;
					if (j%2==0 && vp > 0) {
						curRowHeight += 1;
						vp--;
					}
					ry += curRowHeight/2;
					
					//ry = curRowHeight * (j+0.5) + vpadding*(j+1);
					
					answerText = TextField(answerArray[j]);
					findFontSize(answerText, minFontSize);
					answerText.width = answerText.textWidth+4;
					answerText.height = answerText.textHeight+4;
					answerText.textColor = colFill;
					answerText.y = ry-answerText.height/2;
					if (answerText.width > maxAnswerWidth) maxAnswerWidth = answerText.width;
					
					percentText = TextField(percentArray[j]);
					findFontSize(percentText, minFontSize);
					percentText.width = percentText.textWidth+4;
					percentText.height = percentText.textHeight+4;
					percentText.textColor = colFill;
					percentText.x = graphX + graphWidth - hpadding - percentText.width;
					percentText.y = ry-percentText.height/2;
					if (percentText.width > maxPercentWidth) maxPercentWidth = percentText.width;
					
				}
				
				var countText:TextField;
				var maxBarWidth:int = graphWidth - (hpadding*4) - maxAnswerWidth - maxPercentWidth;
				var barStartX:int = graphX + maxAnswerWidth + (hpadding*2);
				
				for (j=0, vp=extraVPixels, ry=graphY, curRowHeight=0; j<_data.length; j++) {
					ry += Math.round(curRowHeight/2)+vpadding; // add the last row's height plus padding
					
					curRowHeight = avgRowHeight;
					if (j%2==0 && vp > 0) {
						curRowHeight += 1;
						vp--;
					}
					ry += curRowHeight/2;
					
					//ry = curRowHeight * (j+0.5) + vpadding*(j+1);
					
					// draw rect
					var rectWidth:int = maxBarWidth*(_data[j].v/largestVal);
					var	rectangle = new Rect();
					rectangle.stroke = new SolidColorStroke(uint(colFill), 2);
					rectangle.fill = new SolidColor(colFill);
					rectangle.x = barStartX;
					rectangle.y = ry-curRowHeight/2;
					rectangle.width = rectWidth;
					rectangle.height = curRowHeight;
					canvas.addElement(rectangle);
					_pollRects.addItem(rectangle);
					// add vote count in middle of rect
					countText = _textFields[currTFIdx++]; // new TextField();
					countText.text = _data[j].v;
					countText.width = startingLabelWidth;
					countText.height = curRowHeight;
					countText.textColor = bgFill;
					countText.selectable = false;
					_pollContainer.addChild(countText);
					findFontSize(countText, minFontSize);
					countText.width = countText.textWidth+4;
					countText.height = countText.textHeight+4;
					countText.y = ry-countText.height/2;
					if (countText.width > rectWidth) {
						countText.x = barStartX + rectWidth + hpadding/2;
						countText.textColor = colFill;
					} else {
						countText.x = barStartX + rectWidth/2 - countText.width/2;
						countText.textColor = bgFill;
					}
				}
			}
		}
		
		private function findFontSize(textField:TextField, defaultSize:Number):int {
			var tFormat:TextFormat = new TextFormat();
			tFormat.size = defaultSize;
			tFormat.font = "arial";
			tFormat.align = TextFormatAlign.CENTER;
			textField.setTextFormat(tFormat);
			var size:Number = defaultSize;
			while((textField.textWidth+4 > textField.width || textField.textHeight+4 > textField.height) && size > 0) {
				size = size - 1;
				tFormat.size = size;
				textField.setTextFormat(tFormat);
			}
			
			return size;
		}
		
		private function drawRect(canvas:IWhiteboardCanvas, zoom:Number):void {
			
			var arrayEnd:Number = points.length;
			var startX:Number = denormalize(21.845575, canvas.width);
			var startY:Number = denormalize(23.145401, canvas.height);
			var width:Number = denormalize(46.516006, canvas.width) - startX;
			var height:Number = denormalize(61.42433, canvas.height) - startY;
			
			var	rectangle = new Rect();
			rectangle.stroke = new SolidColorStroke(uint(0), 1 * zoom);
			rectangle.x = startX;
			rectangle.y = startY;
			rectangle.width = width;
			rectangle.height = height;
			canvas.addElement(rectangle);
			_pollRects.addItem(rectangle);
		}
		
		override public function draw(canvas:IWhiteboardCanvas, zoom:Number):void {
			var arrayEnd:Number = points.length;
			var startX:Number = denormalize(points[0], canvas.width);
			var startY:Number = denormalize(points[1], canvas.height);
			var pwidth:Number = denormalize(points[2], canvas.width);
			var pheight:Number = denormalize(points[3], canvas.height);
			
			var ans:Array = new Array();
			for (var j:int = 0; j < result.length; j++) {
				var ar:Object = result[j];
				var localizedKey: String = ResourceManager.getInstance().getString('resources', 'bbb.polling.answer.' + ar.key);
				
				if (localizedKey == null || localizedKey == "" || localizedKey == "undefined") {
					localizedKey = ar.key;
				} 
				var rs:Object = {a: localizedKey, v: ar.num_votes as Number};
				ans.push(rs);
			}
			
			data = ans;
			makeTextFields((result != null ? result.length*3 : 0), canvas);
			
			_relX = startX;
			_relY = startY;
			
			updateDisplayList(pwidth, pheight, canvas);
			canvas.addElement(_pollContainer);
			
		}
	}
}