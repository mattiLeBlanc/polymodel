
PolyModel
-------------

PolyModel is a package that simulates the ng-model principal of Angular for Polymer elements with Meteor Blaze. It also works for regular HTML elements.

I know there are already other packages like ViewModel, however the big difference is that this package ony requires you to add `data-model` attributes to your form elements. Similar as with ng-model.

Technically what PolyModel does is scan the template structure onCreate for model elements and then creates a structure of ReactiveVars based on the way you set up your model.

Installation
-------------------
Add the package to your project like this:
```
meteor add leblanc:polymodel
```

Setup a model
-------------------
Polymodel only requires you to call the polymodel function on your instance.
```
Template.myTemplateInstance.created = function() {
    var instance = this
    ...some code
};

// init PolyModel for this template instance
Template.myTemplateInstance.polymodel();
```
In your markup you just add
```
    <form name="actionForm">
        <div>
            <label>Your dad's first name</label>
            <input type="text" data-model="family.father.firstname">
        </div>
        <div>
            <label>Your dad's last name</label>
            <input type="text" data-model="family.father.lastname">
        </div>
        <!-- Polymer 0.5  element -->
        <paper-radio-group selected="yes" data-model="family.isRoyal">
            <paper-radio-button name="yes" label="Yes" />
            <paper-radio-button name="no" label="No" />
        </paper-radio-group>
        <div>
            <label>What city are you located now?</label>
            <input type="text" data-model="city">
        </div>
    </form>
```

In this example you see that we set our `data-model` attributes to the relevant tags. Bob is your uncle.

**Attribute placement for polymer elements**
In case of Polymer elements you have to set them on the correct level where you normally would use an event listener.
Polymodel follows the strict Polymer API in how to retrieve the relevant value of an element.

Date-model structure and Reactivity
-------
In above example you see different paths, `family.father.lastname` or `family.isRoyal` or even a singular path `city`.
This PolyModel's way of defining your data structure.

In your `TemplateInstance` object, the model for the above form would look like
```
instance: {
    family:
    {
        father: {
            firstname: 'value',
            lastname: 'value'
        },
        isRoyal: 'value'
    },
    city: 'value'
}
```
As you can see all values sharing the same path (partially) are merged.

Right now **only the top level node** is a ReactiveVar.  This means that the `family` variable of the TemplateInstance in our example is updated when any of it's siblings are updated.
This means that if you update one variable sibling (`firstname`), your whole `family` model automatically is updated.

## So how does it work with my template Helper?  ##
Well, pretty simple. Knowing that the **top level node** is Reactive, you have to do something like this
```
Template.myTemplateInstance.helpers( {
    // return dad's first name
    dadsFirstName: function() {
        instance = Template.instance()
        return instance.family.get().father.firstname
    },

    // return dad's last name
    dadsLastName: function() {
        instance = Template.instance()
        return instance.family.get().father.lastname
    },

    // return city I submitted this form
    city: function() {
        instance = Template.instance()
        return instance.city.get()
    }
} )
```

Of course you could just return the toplevel (`family`) variable which returns a `father` object to your view.

```
Template.myTemplateInstance.helpers( {
    // return dad's first name
    father: function() {
        instance = Template.instance()
        return instance.family.get()
    }
} )
```

## Finally, there is a Polymodel object ##
In your templateInstance within your Helper of Events you will find a `polymodel` object instance which holds your whole form structure they way you set it up. The values are **actual**.

The reason I exposed this is so that you can grap the whole `family` object in one go and pass it on to your HTTP request, instead of digging it out of your template instance object.
The later one is only there to make the Reactivity work with your helpers.

To get a clean export of the structure, you can use the `get()` function:
```
instance.polymodel.get( 'family' )
```
If you  access the form structure directly from the PolyModel object, that is fine however it does expose some config key/value pairs.

## To Do ##

 - hide PolyForm config like 'trigger' under prototype, without getting the dependency tracker error
 - support more polymer elements
 - support polymer 0.5 and 1.0