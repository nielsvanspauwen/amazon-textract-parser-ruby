require "amazon-textract-parser-ruby/version"

module AmazonTRP
  class Error < StandardError; end
  
  def AmazonTRP.stable_sort_by(e)
    e.sort_by.with_index { |x, idx| [yield(x), idx] }
  end

  
  class BoundingBox
    attr_reader :width
    attr_reader :height
    attr_reader :left
    attr_reader :top
    
    def initialize(width, height, left, top)
      @width = width
      @height = height
      @left = left
      @top = top
    end
    
    def to_s
      "width: #{@width}, height: #{@height}, left: #{@left}, top: #{@top}"
    end
    
    def right
      @left + @width
    end
    
    def bottom
      @top + @height
    end
  end
  
  
  class Point
    attr_reader :x
    attr_reader :y
    
    def initialize(x, y)
      @x = x
      @y = y
    end
    
    def to_s
      "(#{@x}, #{@y})"
    end
  end
  
  
  class Geometry
    attr_reader :boundingBox
    attr_reader :polygon
    
    def initialize(geometry)
      bbox = geometry[:bounding_box]
      pg = geometry[:polygon]
      @boundingBox = BoundingBox.new(bbox[:width], bbox[:height], bbox[:left], bbox[:top])
      @polygon = pg.map{|p| Point.new(p[:x], p[:y])}
    end
    
    def to_s
      "BoundingBox: #{@bounding_box}"
    end
  end
  
  
  class Word
    attr_reader :confidence
    attr_reader :geometry
    attr_reader :id
    attr_reader :text
    attr_reader :block
    
    def initialize(block, blockMap)
      @block = block
      @confidence = block[:confidence]
      @geometry = Geometry.new(block[:geometry])
      @id = block[:id]
      @text = block[:text] || ""
    end
    
    def to_s
      @text
    end
  end
  
  
  class Line
    attr_reader :confidence
    attr_reader :geometry
    attr_reader :id
    attr_reader :words
    attr_reader :text
    attr_reader :block
    
    def initialize(block, blockMap)
      @block = block
      @confidence = block[:confidence]
      @geometry = Geometry.new(block[:geometry])
      @id = block[:id]
      
      @text = block[:text] || ""
      
      @words = []
      if block[:relationships]
        block[:relationships].each do |rs|
          if rs[:type] == 'CHILD'
            rs[:ids].each do |cid|
              if blockMap[cid][:block_type] == "WORD"
                @words.append(Word.new(blockMap[cid], blockMap))
              end
            end
          end
        end
      end
    end
    
    def to_s
      s = "Line: "
      s = s + @text + "\n"
      s = s + "Words: "
      @words.each do |word|
        s = s + "[#{word}]"
      end
      return s
    end
  end
  
  
  class SelectionElement
    attr_reader :confidence
    attr_reader :geometry
    attr_reader :id
    attr_reader :selectionStatus
    
    def initialize(block, blockMap)
      @confidence = block[:confidence]
      @geometry = Geometry.new(block[:geometry])
      @id = block[:id]
      @selectionStatus = block[:selection_status]
    end
  end
  
  
  class FieldKey
    attr_reader :confidence
    attr_reader :geometry
    attr_reader :id
    attr_reader :content
    attr_reader :text
    attr_reader :block
    
    def initialize(block, children, blockMap)
      @block = block
      @confidence = block[:confidence]
      @geometry = Geometry.new(block[:geometry])
      @id = block[:id]
      @text = ""
      @content = []
      
      t = []
      children.each do |eid|
        wb = blockMap[eid]
        if wb[:block_type] == "WORD"
          w = Word.new(wb, blockMap)
          @content.append(w)
          t.append(w.text)
        end
      end
      @text = t.join(' ') if t
    end
    
    def to_s
      @text
    end
  end
  
  
  class FieldValue
    attr_reader :confidence
    attr_reader :geometry
    attr_reader :id
    attr_reader :content
    attr_reader :text
    attr_reader :block
    
    def initialize(block, children, blockMap)
      @block = block
      @confidence = block[:confidence]
      @geometry = Geometry.new(block[:geometry])
      @id = block[:id]
      @text = ""
      @content = []
      
      t = []
      children.each do |eid|
        wb = blockMap[eid]
        if wb[:block_type] == "WORD"
          w = Word.new(wb, blockMap)
          @content.append(w)
          t.append(w.text)
        elsif wb[:block_type] == "SELECTION_ELEMENT"
          se = SelectionElement.new(wb, blockMap)
          @content.append(se)
          t.append(se.selectionStatus)
        end
      end
      
      @text = t.join(' ') if t
    end
    
    def to_s
      @text
    end
  end
  
  
  class Field
    attr_reader :key
    attr_reader :value
    
    def initialize(block, blockMap)
      @key = nil
      @value = nil
      
      block[:relationships].each do |item|
        if item[:type] == "CHILD"
          @key = FieldKey.new(block, item[:ids], blockMap)
        elsif item[:type] == "VALUE"
          item[:ids].each do |eid|
            vkvs = blockMap[eid]
            if vkvs[:entity_types].include?('VALUE')
              if vkvs.has_key?(:relationships)
                vkvs[:relationships].each do |vitem|
                  @value = FieldValue.new(vkvs, vitem[:ids], blockMap) if vitem[:type] == "CHILD"
                end
              end
            end
          end
        end
      end
    end
    
    def to_s
      k = ""
      v = ""
      
      k = @key.to_s if @key
      v = @value.to_s if @value
      
      return "Field: #{k} = #{v}"
    end
  end
  
  
  class Form
    attr_reader :fields
    
    def initialize
      @fields = []
      @fieldsMap = {}
    end
    
    def addField(field)
      @fields.append(field)
      @fieldsMap[field.key.text] = field
    end
    
    def to_s
      s = "Form fields:\n"
      @fields.each do |field|
        s = s + field.to_s + "\n"
      end
      return s
    end
    
    def getFieldByKey(key)
      @fieldsMap[key]
    end
    
    def findFieldsByKey(key)
      searchKey = key.downcase()
      results = []
      @fields.each do |field|
        if field.key && (field.key.text.downcase.include?(searchKey))
          results.append(field)
        end
      end
      return results
    end
    
    def findFieldByKey(key)
      fields = findFieldsByKey(key)
      # Choose the shortest match
      match = nil
      matchLength = 0
      fields.each do |f|
        if match.nil? || f.key.text.length < matchLength
          match = f
          matchLength = f.key.text.length
        end
      end
      return match
    end
  end
  
  
  class Cell
    attr_reader :confidence
    attr_reader :rowIndex
    attr_reader :columnIndex
    attr_reader :rowSpan
    attr_reader :columnSpan
    attr_reader :geometry
    attr_reader :id
    attr_reader :content
    attr_reader :text
    attr_reader :block
    
    def initialize(block, blockMap)
      @block = block
      @confidence = block[:confidence]
      @rowIndex = block[:row_index]
      @columnIndex = block[:column_index]
      @rowSpan = block[:row_span]
      @columnSpan = block[:column_span]
      @geometry = Geometry.new(block[:geometry])
      @id = block[:id]
      @content = []
      @text = ""
      if block[:relationships]
        block[:relationships].each do |rs|
          if rs[:type] == 'CHILD'
            for cid in rs[:ids]
              blockType = blockMap[cid][:block_type]
              if blockType == "WORD"
                w = Word.new(blockMap[cid], blockMap)
                @content.append(w)
                @text = @text + w.text + ' '
              elsif blockType == "SELECTION_ELEMENT"
                se = SelectionElement.new(blockMap[cid], blockMap)
                @content.append(se)
                @text = @text + se.selectionStatus + ', '
              end
            end
          end
        end
      end
      @text = @text.strip
    end
    
    def to_s
      @text
    end
  end
  
  
  class Row
    attr_reader :cells
    
    def initialize
      @cells = []
    end
    
    def to_s
      s = ""
      @cells.each do |cell|
        s = s + "[#{cell}]"
      end
      return s
    end
  end
  
  
  class Table
    attr_reader :confidence
    attr_reader :geometry
    attr_reader :id
    attr_reader :rows
    attr_reader :block
    
    def initialize(block, blockMap)
      @block = block
      
      @confidence = block[:confidence]
      @geometry = Geometry.new(block[:geometry])
      
      @id = block[:id]
      @rows = []
      
      ri = 1
      row = Row.new()
      cell = nil
      if block[:relationships]
        block[:relationships].each do |rs|
          if rs[:type] == 'CHILD'
            for cid in rs[:ids]
              cell = Cell.new(blockMap[cid], blockMap)
              if cell.rowIndex > ri
                @rows.append(row)
                row = Row.new()
                ri = cell.rowIndex
              end
              row.cells.append(cell)
            end
            @rows.append(row) if row && row.cells
          end
        end
      end
    end
    
    def to_s
      s = "Table:\n"
      @rows.each do |row|
        s = s + row.to_s + "\n"
      end
      return s
    end
  end
  
  
  class Page
    attr_reader :blocks
    attr_reader :text
    attr_reader :lines
    attr_reader :form
    attr_reader :tables
    attr_reader :content
    attr_reader :geometry
    attr_reader :id
    
    def initialize(blocks, blockMap)
      @blocks = blocks
      @text = ""
      @lines = []
      @form = Form.new()
      @tables = []
      @content = []
      
      _parse(blockMap)
    end
    
    def to_s
      s = "Page:\n"
      @content.each do |item|
        s = s + item.to_s + "\n"
      end
      return s
    end
    
    def _parse(blockMap)
      @blocks.each do |item|
        if item[:block_type] == "PAGE"
          @geometry = Geometry.new(item[:geometry])
          @id = item[:id]
        elsif item[:block_type] == "LINE"
          l = Line.new(item, blockMap)
          @lines.append(l)
          @content.append(l)
          @text = @text + l.text + '\n'
        elsif item[:block_type] == "TABLE"
          t = Table.new(item, blockMap)
          @tables.append(t)
          @content.append(t)
        elsif item[:block_type] == "KEY_VALUE_SET"
          if item[:entity_types].include?('KEY')
            f = Field.new(item, blockMap)
            if f.key
              @form.addField(f)
              @content.append(f)
            end
          end
        end
      end
    end
    
    def getLinesInReadingOrder
      columns = []
      lines = []
      @lines.each do |item|
        column_found = false
        columns.each_with_index do |column, index|
          bbox_left = item.geometry.boundingBox.left
          bbox_right = item.geometry.boundingBox.right
          bbox_centre = item.geometry.boundingBox.left + item.geometry.boundingBox.width/2
          column_centre = column[:left] + ((column[:right] - column[:left]) / 2)
          if (bbox_centre > column[:left] && bbox_centre < column[:right]) || (column_centre > bbox_left && column_centre < bbox_right)
            # Bbox appears inside the column
            lines.append({:column => index, :text => item.text})
            column_found = true
            break
          end
        end
        if !column_found
          columns.append({:left => item.geometry.boundingBox.left, :right => item.geometry.boundingBox.right})
          lines.append({:column => columns.count - 1, :text => item.text})
        end
      end
      
      return AmazonTRP::stable_sort_by(lines) {|x| x[:column]}
    end
    
    def getTextInReadingOrder
      lines = getLinesInReadingOrder()
      text = ""
      lines.each do |line|
        text = text + line[:text] + "\n"
      end
      return text
    end
    
    def getLinesInBoundingBox(boundingBox)
      lines = []
      @lines.each do |line|
        line_bbox = line.geometry.boundingBox
        if (line_bbox.left >= boundingBox.left &&
          line_bbox.left <= boundingBox.right &&
          line_bbox.top >= boundingBox.top &&
          line_bbox.top <= boundingBox.bottom)
          lines.append(line)
        end
      end
      return lines
    end
  end
  
  
  class Document
    attr_reader :blocks
    attr_reader :pageBlocks
    attr_reader :pages
    
    def initialize(responsePages)
      @responsePages = responsePages.is_a?(Array) ? responsePages : [responsePages]
      @pages = []
      _parse()
    end
    
    def to_s
      s = "\nDocument:\n"
      @pages.each do |p|
        s = s + p.to_s + "\n\n"
      end
      return s
    end
    
    def _parseDocumentPagesAndBlockMap
      blockMap = {}
      
      documentPages = []
      documentPage = nil
      @responsePages.each do |page|
        unless page[:blocks].nil?
          page[:blocks].each do |block|
            if block.has_key?(:block_type) && block.has_key?(:id)
              blockMap[block[:id]] = block
            end
            
            if block[:block_type] == 'PAGE'
              documentPages.append({:blocks => documentPage}) if documentPage
              documentPage = []
              documentPage.append(block)
            else
              documentPage.append(block)
            end
          end
        end
      end
      documentPages.append({:blocks => documentPage}) if documentPage
      return documentPages, blockMap
    end
    
    def _parse
      @responseDocumentPages, @blockMap = _parseDocumentPagesAndBlockMap()
      @responseDocumentPages.each do |documentPage|
        page = Page.new(documentPage[:blocks], @blockMap)
        @pages.append(page)
      end
    end
    
    def getBlockById(blockId)
      return @blockMap[blockId] if @blockMap && @blockMap.has_key?(blockId)
      return nil
    end
  end
  
end
