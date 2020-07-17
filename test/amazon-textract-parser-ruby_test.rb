require "test_helper"
require 'active_support/core_ext/hash/keys'
$libdir = File.expand_path(File.dirname(__FILE__))


class AmazonTRP::Test < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::AmazonTRP::VERSION
  end

  def test_bounding_box
    width = 0.01
    height = 0.02
    left = 0.3
    top = 0.5

    bbox = AmazonTRP::BoundingBox.new(width, height, left, top)

    assert_equal(bbox.top, top)
    assert_equal(bbox.bottom, top + height)
    assert_equal(bbox.height, height)
    assert_equal(bbox.left, left)
    assert_equal(bbox.right, left + width)
    assert_equal(bbox.width, width)
    assert_equal(bbox.to_s, "width: #{width}, height: #{height}, left: #{left}, top: #{top}")
  end

  def test_document
    data = Marshal.load(File.binread("#{$libdir}/testdata")).deep_symbolize_keys!
    doc = AmazonTRP::Document.new(data)
    assert(doc)
    assert_equal(1, doc.pages.count)
    assert_equal(49, doc.pages[0].lines.count)

    assert_equal("Testing Amazon Textract", doc.pages[0].lines[0].text)
    assert_equal(3, doc.pages[0].lines[0].words.count)

    assert_equal(7, doc.pages[0].form.fields.count)
    assert_equal("Niels Vanspauwen", doc.pages[0].form.findFieldByKey("Name").value.to_s)
    assert_equal("Software Engineer", doc.pages[0].form.findFieldByKey("Occupation").value.to_s)
    assert_equal("Belgium", doc.pages[0].form.findFieldByKey("country").value.to_s)
    assert_equal("SELECTED", doc.pages[0].form.findFieldByKey("male").value.to_s)
    assert_equal("NOT_SELECTED", doc.pages[0].form.findFieldByKey("female").value.to_s)
    
    assert_equal(2, doc.pages[0].tables.count)
    assert_equal(4, doc.pages[0].tables[0].rows.count)
    assert_equal(4, doc.pages[0].tables[0].rows[0].cells.count)
    assert_equal("Item", doc.pages[0].tables[0].rows[0].cells[0].text)
  end

  def test_multi_column
    data = Marshal.load(File.binread("#{$libdir}/testdata_multicolumn")).deep_symbolize_keys!
    doc = AmazonTRP::Document.new(data)
    assert(doc)
    assert_equal(1, doc.pages.count)

    lines = doc.pages[0].getLinesInReadingOrder()
    assert_equal(15, lines.count)

    assert_equal("Two-column text", lines[0][:text])
    assert_equal("This is a simple test of Amazon Textract. Amazon", lines[1][:text])
    assert_equal("Textract is a service that automatically extracts text", lines[2][:text])
    assert_equal("and data from scanned documents.", lines[3][:text])
    assert_equal("Amazon Textract goes beyond simple optical", lines[4][:text])
    assert_equal("character recognition (OCR) to also identify the", lines[5][:text])
    assert_equal("contents of fields in forms and information stored in", lines[6][:text])
    assert_equal("tables.", lines[7][:text])
    assert_equal("Based on the bounding box information, you can", lines[8][:text])
    assert_equal("even detect multi-column text correctly. However,", lines[9][:text])
    assert_equal("the method in the TRP only works if the whole", lines[10][:text])
    assert_equal("document has the same number of columns.", lines[11][:text])
    assert_equal("Extending it to handle multi-column section is left as", lines[12][:text])
    assert_equal("an exercise to the reader", lines[13][:text])
  end
end
