package
{
	import flash.display.Sprite;
	
	public class NodePath extends Sprite
	{
		public var startNode:Node;
		public var endNode:Node;
		
		public function NodePath(startNode:Node,endNode:Node)
		{
			super();
			
			this.startNode = startNode;
			this.endNode = endNode;
			
			updateDisplay();
		}
		
		public function updateDisplay():void
		{
			var lineWeight:Number = 1.5;
			this.graphics.clear();
			this.graphics.lineStyle(lineWeight * 2,0x222222,0.2);
			this.graphics.moveTo(startNode.x,startNode.y);
			this.graphics.lineTo(endNode.x,endNode.y);	
			this.graphics.lineStyle(lineWeight,0xFF6699,1);
			this.graphics.moveTo(startNode.x,startNode.y);
			this.graphics.lineTo(endNode.x,endNode.y);
			this.graphics.endFill();
		}
	}
}