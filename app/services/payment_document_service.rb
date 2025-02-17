# frozen_string_literal: true

# Provides methods to generate Invoice, Avoir or PaymentSchedule references
class PaymentDocumentService
  class << self
    def generate_reference(document, date: DateTime.current)
      pattern = Setting.get('invoice_reference')

      reference = replace_invoice_number_pattern(pattern, document.created_at)
      reference = replace_date_pattern(reference, date)

      if document.is_a? Avoir
        # information about refund/avoir (R[text])
        reference.gsub!(/R\[([^\]]+)\]/, '\1')

        # remove information about online selling (X[text])
        reference.gsub!(/X\[([^\]]+)\]/, ''.to_s)
        # remove information about payment schedule (S[text])
        reference.gsub!(/S\[([^\]]+)\]/, ''.to_s)
      elsif document.is_a? PaymentSchedule
        # information about payment schedule
        reference.gsub!(/S\[([^\]]+)\]/, '\1')
        # remove information about online selling (X[text])
        reference.gsub!(/X\[([^\]]+)\]/, ''.to_s)
        # remove information about refunds (R[text])
        reference.gsub!(/R\[([^\]]+)\]/, ''.to_s)
      elsif document.is_a? Invoice
        # information about online selling (X[text])
        if document.paid_by_card?
          reference.gsub!(/X\[([^\]]+)\]/, '\1')
        else
          reference.gsub!(/X\[([^\]]+)\]/, ''.to_s)
        end

        # remove information about refunds (R[text])
        reference.gsub!(/R\[([^\]]+)\]/, ''.to_s)
        # remove information about payment schedule (S[text])
        reference.gsub!(/S\[([^\]]+)\]/, ''.to_s)
      else
        raise TypeError
      end

      reference
    end

    def generate_order_number(document)
      pattern = Setting.get('invoice_order-nb')

      # global document number (nn..nn)
      reference = pattern.gsub(/n+(?![^\[]*\])/) do |match|
        pad_and_truncate(number_of_invoices(document.is_a?(Order) ? 'order' : 'global'), match.to_s.length)
      end

      reference = replace_invoice_number_pattern(reference, document.created_at)
      replace_date_pattern(reference, document.created_at)
    end

    private

    ##
    # Output the given integer with leading zeros. If the given value is longer than the given
    # length, it will be truncated.
    # @param value {Integer} the integer to pad
    # @param length {Integer} the length of the resulting string.
    ##
    def pad_and_truncate(value, length)
      value.to_s.rjust(length, '0').gsub(/^.*(.{#{length},}?)$/m, '\1')
    end

    ##
    # Returns the number of current invoices in the given range around the current date.
    # If range is invalid or not specified, the total number of invoices is returned.
    # @param range {String} 'day', 'month', 'year'
    # @param date {Date} the ending date
    # @return {Integer}
    ##
    def number_of_invoices(range, date = DateTime.current)
      case range.to_s
      when 'day'
        start = date.beginning_of_day
      when 'month'
        start = date.beginning_of_month
      when 'year'
        start = date.beginning_of_year
      else
        return get_max_id(Invoice) + get_max_id(PaymentSchedule) + get_max_id(Order)
      end
      ending = date
      return Invoice.count + PaymentSchedule.count + Order.count unless defined? start

      Invoice.where('created_at >= :start_date AND created_at <= :end_date', start_date: start, end_date: ending).length +
        PaymentSchedule.where('created_at >= :start_date AND created_at <= :end_date', start_date: start, end_date: ending).length +
        Order.where('created_at >= :start_date AND created_at <= :end_date', start_date: start, end_date: ending).length
    end

    ##
    # Replace the date elements in the provided pattern with the date values, from the provided date
    # @param reference {string}
    # @param date {DateTime}
    ##
    def replace_date_pattern(reference, date)
      copy = reference.dup

      # full year (YYYY)
      copy.gsub!(/(?![^\[]*\])YYYY(?![^\[]*\])/, date.strftime('%Y'))
      # year without century (YY)
      copy.gsub!(/(?![^\[]*\])YY(?![^\[]*\])/, date.strftime('%y'))

      # abbreviated month name (MMM)
      copy.gsub!(/(?![^\[]*\])MMM(?![^\[]*\])/, date.strftime('%^b'))
      # month of the year, zero-padded (MM)
      copy.gsub!(/(?![^\[]*\])MM(?![^\[]*\])/, date.strftime('%m'))
      # month of the year, non zero-padded (M)
      copy.gsub!(/(?![^\[]*\])M(?![^\[]*\])/, date.strftime('%-m'))

      # day of the month, zero-padded (DD)
      copy.gsub!(/(?![^\[]*\])DD(?![^\[]*\])/, date.strftime('%d'))
      # day of the month, non zero-padded (DD)
      copy.gsub!(/(?![^\[]*\])DD(?![^\[]*\])/, date.strftime('%-d'))

      copy
    end

    ##
    # Replace the document number elements in the provided pattern with counts from the database
    # @param reference {string}
    ##
    def replace_invoice_number_pattern(reference, date)
      copy = reference.dup

      # document number per year (yy..yy)
      copy.gsub!(/y+(?![^\[]*\])/) do |match|
        pad_and_truncate(number_of_invoices('year', date), match.to_s.length)
      end
      # document number per month (mm..mm)
      copy.gsub!(/m+(?![^\[]*\])/) do |match|
        pad_and_truncate(number_of_invoices('month', date), match.to_s.length)
      end
      # document number per day (dd..dd)
      copy.gsub!(/d+(?![^\[]*\])/) do |match|
        pad_and_truncate(number_of_invoices('day', date), match.to_s.length)
      end

      copy
    end

    ##
    # Return the maximum ID from the database, for the given class
    # @param klass {ActiveRecord::Base}
    ##
    def get_max_id(klass)
      ActiveRecord::Base.connection.execute("SELECT max(id) FROM #{klass.table_name}").getvalue(0, 0) || 0
    end
  end
end
