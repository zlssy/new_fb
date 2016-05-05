Formbuilder.registerField 'address',

  order: 50

  view: """
    <div class='input-line'>
      <span class='street'>
        <input type='text' />
        <label>街道</label>
      </span>
    </div>

    <div class='input-line'>
      <span class='city'>
        <input type='text' />
        <label>城市</label>
      </span>

      <span class='state'>
        <input type='text' />
        <label>省</label>
      </span>
    </div>

    <div class='input-line'>
      <span class='zip'>
        <input type='text' />
        <label>邮编</label>
      </span>

      <span class='country'>
        <select><option>请选择</option></select>
        <label>国家</label>
      </span>
    </div>
  """

  edit: ""

  addButton: """
    <span class="symbol"><span class="fa fa-home"></span></span> 地址
  """
